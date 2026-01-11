import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingEventPage extends StatelessWidget {
  const UpcomingEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = [
      {
        'title': 'AU Website',
        'imageUrl': 'assets/images/au_logo.jpg',
        'isAsset': true,
        'url': 'https://www.au.edu/',
      },
      {
        'title': 'AUSO Instagram',
        'imageUrl': 'assets/images/au_insta.webp',
        'isAsset': true,
        'url': 'https://www.instagram.com/ausoabac',
      },
      {
        'title': 'AU Facebook',
        'imageUrl': 'assets/images/au_facebook.jpg',
        'isAsset': true,
        'url': 'https://www.facebook.com/assumptionuniversity/',
      },
      {
        'title': 'AU YouTube',
        'imageUrl': 'assets/images/au_YT.jpg',
        'isAsset': true,
        'url': 'https://www.youtube.com/@assumptionuniversityofthailand',
      },
      {
        'title': 'AU OIA',
        'imageUrl': 'assets/images/au_oia.jpg',
        'isAsset': true,
        'url': 'https://oia.au.edu/contact',
      },
      {
        'title': 'AU Lms',
        'imageUrl': 'assets/images/au_logo.jpg',
        'isAsset': true,
        'url': 'https://aulms.au.edu/login/index.php',
      },
      {
        'title': 'LMS (MSME)',
        'imageUrl': 'assets/images/au_lmsMSME.png',
        'isAsset': true,
        'url': 'https://lms.msme.au.edu/',
      },
      {
        'title': 'AU (ITs Line Account)',
        'imageUrl': 'assets/images/au_IT.jpg',
        'isAsset': true,
        'url': 'https://line.me/R/ti/p/@076cezgn',
      },
      {
        'title': 'AU (Registrar)',
        'imageUrl': 'assets/images/au_logo.jpg',
        'isAsset': true,
        'url': 'https://registrar.au.edu/',
      },
      {
        'title': 'AU Spark',
        'imageUrl': 'assets/images/au_auspark.jpg',
        'isAsset': true,
        'url': 'https://auspark.au.edu/Account/Login?ReturnUrl=%2F',
      },
      {
        'title': 'AUISC (FB)',
        'imageUrl': 'assets/images/au_auisc.jpg',
        'isAsset': true,
        'url': 'https://www.facebook.com/share/17jao9RHpz/',
      },
      {
        'title': 'Graduate Studies',
        'imageUrl': 'assets/images/au_facebook.jpg',
        'isAsset': true,
        'url': 'https://www.facebook.com/share/17jao9RHpz/',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Clicks'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tap an image to explore",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: events
                    .map(
                      (event) => _eventCard(
                        title: event['title'] as String,
                        imageUrl: event['imageUrl'] as String,
                        isAsset: event['isAsset'] as bool,
                        url: event['url'] as String,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard({
    required String title,
    required String imageUrl,
    required bool isAsset,
    required String url,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.deepOrange, width: 2),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final uri = Uri.parse(url);
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('Could not launch $uri');
                }
              },
              child: AspectRatio(
                aspectRatio: 2.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isAsset
                      ? Image.asset(imageUrl, fit: BoxFit.contain)
                      : Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              "Tap image for details",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
