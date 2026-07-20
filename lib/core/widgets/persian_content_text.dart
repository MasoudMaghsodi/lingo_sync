import 'package:flutter/material.dart';

/// Renders text that is *always* Persian regardless of the app's current
/// UI language toggle — AI-generated word meanings, summaries,
/// transcripts, and grammar explanations are always produced in Persian
/// by the backend, independent of whatever language the user has the app
/// interface set to.
///
/// The app's ambient `Directionality` (set in `app.dart`) flips between
/// LTR/RTL based on that UI language toggle. When the app is in English
/// mode (ambient LTR) but a widget shows genuinely-Persian AI content
/// without an explicit RTL direction, the paragraph's base direction
/// mismatches its actual script: Flutter lays it out as an LTR paragraph
/// with an embedded RTL run instead of a proper RTL paragraph, which is
/// what causes multi-line Persian text to left-align and visually
/// "jumble" (numbers, punctuation, and even word order within a line can
/// end up in the wrong place). Wrapping in an explicit `Directionality`
/// fixes the base paragraph direction independent of the UI toggle.
class PersianContentText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const PersianContentText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        style: style,
        textAlign: textAlign ?? TextAlign.right,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Same idea as [PersianContentText] but selectable — used for longer
/// always-Persian content (video summaries, full transcript
/// translations) that a user might want to copy.
class PersianContentSelectableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const PersianContentSelectableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SelectableText(
        text,
        style: style,
        textAlign: textAlign ?? TextAlign.right,
      ),
    );
  }
}
