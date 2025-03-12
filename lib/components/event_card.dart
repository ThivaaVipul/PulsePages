import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pulsepages/screens/edit_event_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final String docId;

  const EventCard({super.key, required this.eventData, required this.docId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EditEventPage(eventData: eventData, docId: docId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eventData['imageUrl'] != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: FutureBuilder<Size>(
                      future: _getImageSize(eventData['imageUrl']),
                      builder: (context, snapshot) {
                        double aspectRatio = 3 / 4;

                        if (snapshot.hasData) {
                          final imageSize = snapshot.data!;
                          aspectRatio = imageSize.width / imageSize.height;

                          if (aspectRatio > 1.3) {
                            aspectRatio = 16 / 9;
                          } else if (aspectRatio < 0.75) {
                            aspectRatio = 3 / 4;
                          }
                        }

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          height:
                              snapshot.hasData
                                  ? (snapshot.data!.height /
                                          snapshot.data!.width) *
                                      MediaQuery.of(context).size.width
                                  : 200,
                          child: CachedNetworkImage(
                            imageUrl: eventData['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => _buildImageSkeleton(context),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Theme.of(context).primaryColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        eventData['description'] ?? 'Event',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditEventPage(
                                  eventData: eventData,
                                  docId: docId,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Tooltip(
                          message: "Edit Event",
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    eventData['imageUrl'] == null
                        ? BorderRadius.circular(16)
                        : const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eventData['imageUrl'] == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                            // ignore: deprecated_member_use
                          ).primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          eventData['description'] ?? 'Event',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    eventData['caption'] ?? 'No caption available',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      height: 1.3,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSkeleton(BuildContext context) {
    final amberColor = Theme.of(context).primaryColor;
    // ignore: deprecated_member_use
    final lightAmber = amberColor.withOpacity(0.3);

    return Shimmer.fromColors(
      baseColor: lightAmber,
      highlightColor: Colors.amber[100]!,
      child: Container(color: Colors.white),
    );
  }

  Future<Size> _getImageSize(String url) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(url);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener(
            (ImageInfo info, bool _) {
              final myImage = info.image;
              completer.complete(
                Size(myImage.width.toDouble(), myImage.height.toDouble()),
              );
            },
            onError: (dynamic error, StackTrace? stackTrace) {
              completer.complete(const Size(300, 400));
            },
          ),
        );
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => const Size(300, 400),
    );
  }
}
