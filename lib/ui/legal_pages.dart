import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/weather_controller.dart';
import 'weather_theme.dart';

enum LegalDocument { privacy, terms, cookies, refunds }

const _operator = '[Operator legal name required before launch]';
const _region = '[Country/region required before launch]';
const _contact = '[Privacy contact email required before launch]';
const _address = '[Business address required if required by applicable law]';

String legalTitle(LegalDocument document) => switch (document) {
      LegalDocument.privacy => 'Privacy policy',
      LegalDocument.terms => 'Terms and conditions',
      LegalDocument.cookies => 'Cookie and storage policy',
      LegalDocument.refunds => 'Refund policy',
    };

String legalRouteName(LegalDocument document) => switch (document) {
      LegalDocument.privacy => '/privacy',
      LegalDocument.terms => '/terms',
      LegalDocument.cookies => '/cookies',
      LegalDocument.refunds => '/refunds',
    };

Map<String, WidgetBuilder> get legalPageRoutes => {
      for (final document in LegalDocument.values)
        legalRouteName(document): (_) => LegalPage(document: document),
    };

class LegalPage extends StatelessWidget {
  const LegalPage({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(legalTitle(document)),
          backgroundColor: context.weatherColors.background,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
                children: [
                  Text('FlexiWeather',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Last updated: October 16, 2026',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 22),
                  _LegalContent(document: document),
                  const SizedBox(height: 22),
                  if (document == LegalDocument.privacy ||
                      document == LegalDocument.cookies)
                    const _StorageChoiceControl(),
                  const SizedBox(height: 18),
                  const _BusinessDetails(),
                  const SizedBox(height: 20),
                  Text(
                    'This draft describes the current app code and is not legal advice. It needs the operator details above and a jurisdiction-specific review before public launch.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.weatherColors.muted,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LegalContent extends StatelessWidget {
  const _LegalContent({required this.document});
  final LegalDocument document;

  @override
  Widget build(BuildContext context) => switch (document) {
        LegalDocument.privacy => const _LegalSections(sections: [
            _Section('Who operates FlexiWeather',
                'FlexiWeather is operated by $_operator, based in $_region. Contact: $_contact. These details must be completed before launch.'),
            _Section('What the app handles',
                'There is no account, sign-up, advertising profile, or contact form in the current app. If you search for a place, the place name is sent to Open-Meteo Geocoding. Weather requests send the selected place coordinates to Open-Meteo. If you choose current location, the app asks your device for location permission and sends the resulting coordinates to Open-Meteo to return local weather.'),
            _Section('Information stored on your device',
                'On Android and iOS, the app saves your theme choice, temperature unit, forecast display choice, favorite places, and up to eight cities you explicitly select from search in app storage. Typed search text and one-time device locations are not saved as recent searches. If you explicitly add current location to Favorites, its coordinates are saved as part of that favorite. On the web, these preferences are saved in browser local storage only after you choose “Allow saving”. If you decline, preferences remain session-only.'),
            _Section('Service providers and network data',
                'Requests go directly from your device or browser to Open-Meteo; FlexiWeather has no application server or analytics SDK in the current code. Open-Meteo says its free API may log IP addresses and request URLs, which can contain coordinates, for troubleshooting and abuse prevention, and says those individual logs are deleted after 90 days. Read the provider’s current terms and privacy information at open-meteo.com/en/terms. Your app host may also receive ordinary connection logs; its identity and retention settings depend on where you deploy the site and must be added after choosing a host.'),
            _Section('Why and how long',
                'The app uses a place name only to find a matching place, and coordinates only to request its forecast. Theme choice, forecast display choice, favorites, recent selected cities, and the temperature unit stay on your device until you remove them, clear app/browser data, or uninstall the app. Clear recent searches in the city picker, or use “Clear saved app data” below to remove all saved preferences. We do not receive an account profile or retain a separate copy through a FlexiWeather server.'),
            _Section('Your choices and requests',
                'Location is optional and requested only when you tap the location control; you can deny or revoke it in device settings. Remove a favorite in the Favorites tab. Use “Clear saved app data” below to delete app preferences stored on this device. On the web, you can change the saving choice here; turning it off clears saved app preferences. For a request about information held by a provider or about applicable privacy rights, contact $_contact. Provider-held request logs are subject to the provider’s own policy.'),
            _Section('Privacy rights',
                'Depending on where you live and which law applies, you may have rights to request access to, correction of, or deletion of personal data, object to or restrict certain processing, withdraw consent, or complain to a regulator. Most app preferences can be viewed and removed directly on your device. Send other requests to $_contact; the operator must add any required local representative or regulator contact before launch.'),
            _Section('Children and international use',
                'The current app is not designed to create accounts or collect contact details from children. It is offered worldwide, so local privacy rules may apply depending on your location, the operator, and how the service is promoted. The operator must determine age-related duties, required notices, lawful bases, and any representative or regulator contact required in each target market before launch.'),
            _Section('Changes',
                'If data use or providers change, this policy and the in-app notices must be updated before the change takes effect.'),
          ]),
        LegalDocument.terms => const _LegalSections(sections: [
            _Section('Using the app',
                'FlexiWeather is a free weather information app operated by $_operator (“we”). You may use it for personal, non-commercial purposes while it is available and while you follow these terms and applicable law.'),
            _Section('Weather information and safety',
                'Forecasts and observations come from third parties and can be incomplete, delayed, unavailable, or wrong. Weather information is general information only; do not rely on it for emergency response, aviation, navigation, medical decisions, or other safety-critical decisions. Check official local alerts and qualified sources.'),
            _Section('Third-party data and attribution',
                'Weather requests use Open-Meteo. Its free API is restricted to non-commercial use and subject to its usage limits and terms. Weather data is provided under CC BY 4.0; FlexiWeather displays Open-Meteo attribution. Do not use this free API in a commercial or advertising-supported service without obtaining the appropriate licence. See open-meteo.com/en/terms.'),
            _Section('Availability and changes',
                'We may update, suspend, or discontinue features to maintain or improve the app. Nothing in these terms removes rights that cannot legally be excluded or limited in your jurisdiction.'),
            _Section('Acceptable use',
                'Do not misuse the app or its data services, interfere with their operation, attempt unauthorized access, or use the app unlawfully.'),
            _Section('Operator and applicable law',
                'Operator: $_operator. Contact: $_contact. Operator country/region: $_region. Governing law and dispute venue cannot be completed until the operator’s location and applicable consumer rules are confirmed. Mandatory consumer rights continue to apply.'),
            _Section('Updates to these terms',
                'Updated terms will be posted in the app with a revised date. If a change materially affects users, the app should provide notice before it takes effect.'),
          ]),
        LegalDocument.cookies => const _LegalSections(sections: [
            _Section('Cookies and tracking',
                'The current app code does not set advertising or analytics cookies and contains no analytics SDK, social-media pixel, or third-party iframe. No analytics or ad tracking is currently configured.'),
            _Section('Browser storage',
                'On the web, Flutter’s SharedPreferences implementation uses browser local storage for your theme choice, temperature unit, forecast display choice, favorites, and up to eight cities you explicitly select from search. Typed search text and a one-time current location are not saved as recent searches. This is not a cookie, but some laws regulate similar device storage. The app asks before saving these optional preferences. “Allow saving” stores them on this device; “Continue without saving” keeps the app session-only. Your choice is remembered in browser local storage so the app can honor it. You can change the choice below or clear site data in your browser.'),
            _Section('Hosting and future changes',
                'The deployed website host may set essential security or delivery cookies or collect connection logs. The host is not configured in this repository, so those practices must be checked against the selected hosting provider before launch. If analytics, advertising, or embedded third-party content is added, it must be reviewed and, where required, blocked until valid consent is given.'),
            _Section('Do you need to consent?',
                'There is no advertising or analytics-cookie consent to collect in the current code. Because browser local storage is used for optional saved preferences, this version asks for an affirmative choice before persisting them. Whether additional notices or consent are required depends on the actual host, target countries, and applicable rules.'),
          ]),
        LegalDocument.refunds => const _LegalSections(sections: [
            _Section('Current free service',
                'The current FlexiWeather app has no subscription, paid feature, donation, or in-app purchase flow. There is therefore no FlexiWeather purchase to refund at this time.'),
            _Section('If a payment is introduced',
                'Before introducing paid access, the operator must publish the seller identity, price, billing and renewal terms, cancellation instructions, applicable withdrawal rights, support contact, and refund process before checkout. Purchases made through Apple App Store or Google Play are also subject to their current purchase and refund procedures. Nothing in this page limits mandatory consumer rights.'),
            _Section('Contact',
                'For questions about a charge attributed to FlexiWeather, contact $_contact. This address is a required launch detail and must be configured before any sale.'),
          ]),
      };
}

class _LegalSections extends StatelessWidget {
  const _LegalSections({required this.sections});
  final List<_Section> sections;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(section.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: context.weatherColors.foreground
                          .withValues(alpha: 0.84),
                    )),
            const SizedBox(height: 19),
          ],
        ],
      );
}

class _Section {
  const _Section(this.title, this.body);
  final String title;
  final String body;
}

class _BusinessDetails extends StatelessWidget {
  const _BusinessDetails();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Operator details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 7),
              Text('$_operator · $_region\n$_address\n$_contact',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      )),
            ],
          ),
        ),
      );
}

class _StorageChoiceControl extends StatelessWidget {
  const _StorageChoiceControl();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();
    if (!controller.isWeb) {
      return FilledButton.tonalIcon(
        onPressed: controller.clearSavedAppData,
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('Clear saved app data'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Saved preference choice: ${controller.storageChoiceLabel}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () => controller.setWebStorageConsent(allowed: true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Allow saving preferences'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => controller.setWebStorageConsent(allowed: false),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Turn off saving and clear saved preferences'),
        ),
      ],
    );
  }
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.centered = true});
  final bool centered;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: centered ? WrapAlignment.center : WrapAlignment.start,
        spacing: 4,
        runSpacing: 0,
        children: [
          for (final document in LegalDocument.values)
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(legalRouteName(document)),
              child: Text(legalTitle(document)),
            ),
        ],
      );
}
