import '../../../../shared/widgets/fieldify_painters.dart';

ServiceIconType iconForTrade(String slug) {
  switch (slug) {
    case 'plumbing':
      return ServiceIconType.plumbing;
    case 'electrical':
      return ServiceIconType.electrical;
    case 'carpentry':
      return ServiceIconType.carpentry;
    case 'hvac':
      return ServiceIconType.hvac;
    case 'painting':
      return ServiceIconType.painting;
    default:
      return ServiceIconType.other;
  }
}
