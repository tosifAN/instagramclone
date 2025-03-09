import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'add_post_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _refreshUser();
  }

  void _refreshUser() async {
    await Provider.of<UserProvider>(context, listen: false).refreshUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const FeedScreen(),
          const SearchScreen(),
          const AddPostScreen(),
          const Center(child: Text('Activity')), // TODO: Implement activity screen
          ProfileScreen(uid: user?.uid),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Post',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(
                  user?.photoUrl ?? 'https://via.placeholder.com/150',
                ),
              ),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: isDarkMode ? Colors.white : Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}
