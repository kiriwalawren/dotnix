#!/usr/bin/env perl
# `@-moz-document` only takes effect in privileged sheets, not the plain
# <style> a content script injects into a page (Firefox bug 1035091), so
# Stylus needs the real domain/url-prefix/regexp targets in its own
# sections[].domains/urlPrefixes/regexps fields, not left embedded in the
# code where Gecko silently ignores them.
#
# Splits a compiled catppuccin userstyle into:
#   - stdout: the bare CSS rules inside the outermost `@-moz-document { ... }`
#     block (or the whole input, unchanged, if no such block is found)
#   - stderr: one "<type>\t<value>" line per matcher call found in the
#     `@-moz-document <matchers> { ... }` header
#
# A plain regex can't find the right `{`/`}` boundaries here: matcher
# strings can themselves contain braces (e.g. a `{2}` regex quantifier) and
# parens (nested groups), and some files have Less content (e.g. a mixin
# definition) after the closing brace of the block. This scans character by
# character instead, treating quoted string content as opaque so braces and
# parens inside matcher strings can't be mistaken for structural ones.
use strict;
use warnings;

my $text = do {
  local $/;
  open my $fh, '<', $ARGV[0] or die "$ARGV[0]: $!";
  <$fh>;
};

my $kw = '@-moz-document';
my $len = length($text);
my $start = index($text, $kw);

sub skip_string {
  my ($text, $i, $len) = @_;
  my $j = $i + 1;
  while ($j < $len) {
    my $c = substr($text, $j, 1);
    if ($c eq '\\') { $j += 2; next; }
    if ($c eq '"') { return $j + 1; }
    $j++;
  }
  return $j;
}

if ($start == -1) {
  print $text;
  exit;
}

my $i = $start + length($kw);
my $matchers = '';
my $braceAt;
while ($i < $len) {
  my $c = substr($text, $i, 1);
  if ($c eq '"') {
    my $j = skip_string($text, $i, $len);
    $matchers .= substr($text, $i, $j - $i);
    $i = $j;
    next;
  }
  if ($c eq '{') {
    $braceAt = $i;
    last;
  }
  $matchers .= $c;
  $i++;
}

if (!defined $braceAt) {
  print $text;
  exit;
}

my $depth = 0;
my $bodyStart = $braceAt + 1;
my $bodyEnd;
my $j = $braceAt;
while ($j < $len) {
  my $c = substr($text, $j, 1);
  if ($c eq '"') {
    $j = skip_string($text, $j, $len);
    next;
  }
  if ($c eq '{') { $depth++; $j++; next; }
  if ($c eq '}') {
    $depth--;
    if ($depth == 0) { $bodyEnd = $j; last; }
    $j++;
    next;
  }
  $j++;
}

if (!defined $bodyEnd) {
  print $text;
  exit;
}

print substr($text, $bodyStart, $bodyEnd - $bodyStart);
while ($matchers =~ /\b(domain|regexp|url-prefix|url)\("((?:[^"\\]|\\.)*)"\)/g) {
  print STDERR "$1\t$2\n";
}
