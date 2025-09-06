import 'package:flutter/material.dart';

class UpcomingEventPage extends StatelessWidget {
  const UpcomingEventPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with your app's color scheme
    final events = [
      {
        'title': 'Tech Talk 2025',
        'date': 'Sep 10, 2025',
        'location': 'Main Auditorium',
        'imageUrl':
            'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
      },
      {
        'title': 'Art Festival',
        'date': 'Sep 15, 2025',
        'location': 'Campus Park',
      },
      {
        'title': 'Music Night',
        'date': 'Sep 20, 2025',
        'location': 'Student Center',
      },
      {
        'title': 'Sports Day',
        'date': 'Sep 25, 2025',
        'location': 'Sports Complex',
      },
      {'title': 'Career Fair', 'date': 'Sep 30, 2025', 'location': 'Main Hall'},
      {
        'title': 'Science Expo',
        'date': 'Oct 5, 2025',
        'location': 'Lab Building',
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
        title: const Text('Upcoming Events'),
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
                        title: event['title']!,
                        date: event['date']!,
                        location: event['location']!,
                        imageUrl: event['imageUrl'],
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
    required String date,
    required String location,
    String? imageUrl,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(date, style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(location, style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (imageUrl != null)
                AspectRatio(
                  aspectRatio: 2.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
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
