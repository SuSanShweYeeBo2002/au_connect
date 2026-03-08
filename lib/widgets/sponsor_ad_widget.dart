import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sponsor_ad.dart';
import '../services/sponsor_ad_service.dart';
import '../widgets/optimized_image.dart';

/// Widget to display sponsor ads from backend
class SponsorAdWidget extends StatefulWidget {
  final double width;
  final double height;

  const SponsorAdWidget({super.key, this.width = 276, this.height = 200});

  @override
  State<SponsorAdWidget> createState() => _SponsorAdWidgetState();
}

class _SponsorAdWidgetState extends State<SponsorAdWidget> {
  List<SponsorAd> _ads = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasTrackedImpression = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await SponsorAdService.getActiveAds();
      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoading = false;
        });

        // Track impression for first ad
        if (_ads.isNotEmpty && !_hasTrackedImpression) {
          _trackImpression();
        }
      }
    } catch (e) {
      print('Error loading sponsor ads: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _trackImpression() {
    if (_ads.isNotEmpty && !_hasTrackedImpression) {
      SponsorAdService.trackImpression(_ads[_currentIndex].id);
      _hasTrackedImpression = true;
    }
  }

  Future<void> _handleAdClick() async {
    if (_ads.isEmpty) return;

    final ad = _ads[_currentIndex];

    // Track click
    await SponsorAdService.trackClick(ad.id);

    // Open link
    final uri = Uri.parse(ad.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch ${ad.link}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _ads.isEmpty
          ? _buildEmptyState()
          : _buildAdContent(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[100]!, Colors.grey[200]!],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No Sponsors Yet',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Advertise your business here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdContent() {
    final ad = _ads[_currentIndex];

    return GestureDetector(
      onTap: _handleAdClick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Ad Image
            OptimizedImage(
              imageUrl: ad.image,
              fit: BoxFit.cover,
              width: widget.width,
              height: widget.height,
            ),
            // Sponsor label overlay
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Bottom info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      ad.sponsorName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ad.description != null &&
                        ad.description!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        ad.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
