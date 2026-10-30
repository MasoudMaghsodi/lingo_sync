import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/exam_twin/domain/models/exam_attempt_model.dart';

void main() {
  group('Exam Twin Models Tests', () {
    test('ExamEvaluation fromJson parses criteria and quotes accurately', () {
      final json = {
        'overallBand': 7.0,
        'confidenceMargin': '±0.5',
        'criteria': {
          'fluencyCoherence': {
            'band': 7.0,
            'quote': 'Well, to be completely honest, I believe that...',
            'commentFa': 'روانی کلام بالا با کمترین مکث غیرطبیعی',
          },
          'lexicalResource': {
            'band': 7.5,
            'quote': 'crucial turning point',
            'commentFa': 'استفاده عالی از کالوکیشن‌های آکادمیک',
          },
          'grammaticalRange': {
            'band': 6.5,
            'quote': 'if I would have known',
            'commentFa': 'تلاش برای ساختار پیچیده با خطای جزئی شرطی',
          },
          'pronunciation': {
            'band': 7.0,
            'quote': 'rhythm and stress',
            'commentFa': 'وضوح تلفظ مناسب و تکیه صحیح کلمات',
          },
        },
        'feedbackFa': 'عملکرد شما بسیار خوب بود. در محدوده نمره ۷ قرار دارید.',
        'strengthsFa': ['استفاده از اصطلاحات غنی', 'روانی در بیان ایده'],
        'weaknessesFa': ['دقت در جملات شرطی نوع سوم'],
        'disclaimerFa':
            'این نمره یک تخمین آموزشی داخلی بر پایه هوش مصنوعی است و جایگزین کارنامه رسمی آزمون نمی‌باشد.',
      };

      final eval = ExamEvaluation.fromJson(json);

      expect(eval.overallBand, equals(7.0));
      expect(eval.confidenceMargin, equals('±0.5'));
      expect(eval.criteria.length, equals(4));
      expect(eval.criteria['fluencyCoherence']?.band, equals(7.0));
      expect(
        eval.criteria['fluencyCoherence']?.quote,
        contains('to be completely honest'),
      );
      expect(eval.criteria['lexicalResource']?.band, equals(7.5));
      expect(eval.strengthsFa.length, equals(2));
      expect(eval.weaknessesFa.length, equals(1));
      expect(eval.disclaimerFa, contains('تخمین آموزشی داخلی'));
    });

    test('ExamEvaluation toJson round-trips correctly', () {
      const eval = ExamEvaluation(
        overallBand: 6.5,
        confidenceMargin: '±0.5',
        criteria: {
          'fluencyCoherence': CriterionScore(
            band: 6.5,
            quote: 'for instance',
            commentFa: 'ارتباط خوب',
          ),
        },
        feedbackFa: 'خوب',
        strengthsFa: ['پیوستگی'],
        weaknessesFa: ['گرامر'],
        disclaimerFa: 'تست',
      );

      final json = eval.toJson();
      expect(json['overallBand'], equals(6.5));
      expect(json['feedbackFa'], equals('خوب'));
      expect(json['criteria']['fluencyCoherence']['band'], equals(6.5));
    });
  });
}
