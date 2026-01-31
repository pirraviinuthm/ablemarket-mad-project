import 'package:flutter/material.dart';

class UserProfileShipping extends StatelessWidget {
  const UserProfileShipping({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Point'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ZOOMABLE MAP SECTION ---
            Container(
              height: 300, // Increased height slightly for better visibility
              width: double.infinity,
              color: Colors.grey[300],
              // ClipRect prevents the zoomed image from overflowing outside the container
              child: ClipRect(
                child: InteractiveViewer(
                  // Set limits for how much the user can zoom
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Image itself
                      Image.asset(
                        'assets/location.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      
                      // Pin Marker (Optional - Uncomment if you want the pin to zoom WITH the map)
                      // const Icon(Icons.location_on, size: 50, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
            
            // Note: I moved the Label Overlay OUTSIDE the zoomable area 
            // so it stays fixed and readable while the user zooms the map.
            Center(
              child: Transform.translate(
                offset: const Offset(0, -25), // Pull it up slightly to overlap
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Parit Raja, Johor',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- FIXED ADDRESS DETAILS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.store_mall_directory, color: Color(0xFF2E7D32), size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PPKI Center Collection Point",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "SK Parit Raja,\n86400 Batu Pahat,\nJohor Darul Ta'zim, Malaysia",
                                  style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                // "Fixed" Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline, size: 14, color: Color(0xFF2E7D32)),
                                      SizedBox(width: 5),
                                      Text(
                                        "Fixed Location",
                                        style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // --- INFO BOX ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This address is fixed for all orders. You can pick up your items or expect delivery to this hub.",
                      style: TextStyle(color: Colors.blue, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}