import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../auth/login_screen.dart';
import '../ar/ar_scan_screen.dart';
import '../cart/product.dart';
import '../cart/cart_screen.dart';
import '../home/feedback_chat_screen.dart';
import 'barcode_scan_screen.dart';
import '../../services/product_service.dart';
import '../profile/profile_screen.dart';
import '../profile/order_history_screen.dart';
import '../profile/help_centre_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/budget_progress_bar.dart';

// ─────────────────────────────────────────────
//  BANNER SERVICE
// ─────────────────────────────────────────────
class BannerService {
  static Future<List<String>> fetchBanners() async {
    try {
      final url = Uri.parse("https://www.save2u.com.my/");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        final images = document.querySelectorAll('img');
        List<String> bannerUrls = [];
        for (var img in images) {
          final src = img.attributes['src'];
          if (src != null && src.toLowerCase().contains("banner")) {
            final fullUrl = src.startsWith("http")
                ? src
                : "https://www.save2u.com.my/$src";
            bannerUrls.add(fullUrl);
          }
        }
        return bannerUrls;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────
//  HOME SCREEN  (3-tab shell)
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color secondaryGreen = const Color(0xFF1B5E20);
  final Color accentYellow = const Color(0xFFFFD700);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
        onLogout: () => _logout(context),
      ),
      const ChatScreen(), // Chatbot tab
      const _ProfileTab(),
    ];

    return Scaffold(
      body: tabs[_currentTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF2E7D32)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAB 1 – HOME
// ─────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onLogout;

  const _HomeTab({
    required this.onLogout,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<String> banners = [];
  final PageController _pageController = PageController();

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color secondaryGreen = const Color(0xFF1B5E20);
  final Color accentYellow = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    final fetched = await BannerService.fetchBanners();
    if (mounted) {
      setState(() {
        banners = fetched.isNotEmpty
            ? fetched
            : [
                'assets/images/banner1.jpg',
                'assets/images/banner2.jpg',
                'assets/images/banner3.jpg',
              ];
      });
    }
  }

  void _openScanner() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (scannedCode != null && scannedCode is String) {
      _showProductPreview(scannedCode);
    }
  }

  void _showProductPreview(String code) async {
    // Check local database first for INSTANT loading
    Product? product = productDatabase[code];

    if (product == null) {
      // Show loading dialog for backend fetch
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        product = await ProductService().getProductById(code);
      } catch (e) {
        print("Error fetching product: $e");
      }

      if (mounted) {
        Navigator.pop(context); // Remove loading indicator
      }
    }

    if (!mounted) return;
    if (product == null) return;

    final Product nonNullProduct = product;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Product Detected",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "#$code",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              nonNullProduct.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "RM ${nonNullProduct.price.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 20,
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Weight: ${nonNullProduct.weight}g",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  context.read<CartProvider>().addItem(nonNullProduct);
                  Navigator.pop(context); // Close the modal bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${nonNullProduct.name} added to cart!"),
                      backgroundColor: primaryGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text(
                  "ADD TO CART",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Shopper';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: secondaryGreen,
        centerTitle: true,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'PASARAYA SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Welcome, $displayName ',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: widget.onLogout,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) return const SizedBox();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        cart.items.length.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: banners.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // ── BUDGET TRACKER ──
                  const BudgetProgressBar(),

                  const SizedBox(height: 14),

                  // ── SEARCH BAR ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search groceries...",
                        prefixIcon: Icon(Icons.search, color: primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── BANNER SLIDER ──
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: banners.length,
                      itemBuilder: (context, index) {
                        final image = banners[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: image.startsWith("http")
                                ? Image.network(image, fit: BoxFit.cover)
                                : Image.asset(image, fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: banners.length,
                      effect: WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: primaryGreen,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── QUICK ACTIONS ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _actionButton(
                          icon: Icons.qr_code_scanner,
                          title: "Scan QR",
                          subtitle: "Add items instantly",
                          color: accentYellow,
                          onTap: _openScanner,
                        ),
                        const SizedBox(width: 16),
                        _actionButton(
                          icon: Icons.view_in_ar,
                          title: "Scan with AR",
                          subtitle: "Detect fruits & products",
                          color: primaryGreen,
                          onTap: () async {
                            // Capture messenger before any async gap
                            final messenger =
                                ScaffoldMessenger.of(context);

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ARScanScreen(),
                              ),
                            );

                            if (!mounted) return;

                            // If user tapped "Add to Cart" on the product detail
                            // screen, result will be a Product — add it to cart.
                            if (result is Product) {
                              context.read<CartProvider>().addItem(result);
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text("${result.name} added to cart!"),
                                  backgroundColor: primaryGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── FEATURE CARD ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [primaryGreen, accentYellow],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.storefront, color: Colors.white, size: 40),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Experience smarter grocery shopping with AI scanning and AR product recognition.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAB 3 – PROFILE
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentYellow = const Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        user?.displayName ?? user?.email?.split('@').first ?? 'Shopper';
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'My Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: const Color(0xFF1B5E20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: accentYellow,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Menu tiles
            _menuTile(
              context,
              icon: Icons.person_outline,
              label: 'Edit Profile',
              subtitle: 'Update your name, phone & address',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Order History',
              subtitle: 'View your past receipts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.help_outline,
              label: 'Help Centre',
              subtitle: 'Get support and FAQs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCentreScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.logout,
              label: 'Log Out',
              subtitle: 'Sign out from your account',
              iconColor: Colors.red,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? primaryGreen).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? primaryGreen),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
