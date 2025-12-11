import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingEventPage extends StatelessWidget {
  const UpcomingEventPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with your app's color scheme
    final events = [
      {
        'title': 'AU_Web',
        'imageUrl': 'assets/images/au_logo.jpg',
        'isAsset': true,
        'url': 'https://www.au.edu/',
      },
      {
        'title': 'AUSO_IG',
        'imageUrl': 'assets/images/au_insta.webp',
        'isAsset': true,
        'url': 'https://www.instagram.com/ausoabac?igsh=MWh3aDc5azA0N2xzdQ==',
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
              "Don't miss out on these events!",
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
                        imageUrl: event['imageUrl'] as String?,
                        isAsset: event['isAsset'] as bool? ?? false,
                        url: event['url'] as String? ?? 'https://www.au.edu/',
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
    String? imageUrl,
    bool isAsset = false,
    String url = 'https://www.au.edu/',
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepOrange, width: 2),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              if (imageUrl != null)
                AspectRatio(
                  aspectRatio: 2.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isAsset
                        ? Image.asset(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Asset load error: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image load error: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final Uri uri = Uri.parse(url);
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      // Handle error if URL cannot be launched
                      debugPrint('Could not launch $uri');
                    }
                  },
                  child: const Text('Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
