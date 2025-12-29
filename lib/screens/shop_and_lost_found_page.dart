import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/sell_item_service.dart';
import '../services/lost_item_service.dart';
import '../services/auth_service.dart';

class ShopAndLostFoundPage extends StatefulWidget {
  @override
  _ShopAndLostFoundPageState createState() => _ShopAndLostFoundPageState();
}

class _ShopAndLostFoundPageState extends State<ShopAndLostFoundPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_SellItemsTabState> _sellTabKey = GlobalKey();
  final GlobalKey<_LostAndFoundTabState> _lostTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB label
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop & Lost Found', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.blue,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              tabs: [
                Tab(icon: Icon(Icons.shopping_bag), text: 'Sell Items'),
                Tab(icon: Icon(Icons.find_in_page), text: 'Lost & Found'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SellItemsTab(key: _sellTabKey),
          LostAndFoundTab(key: _lostTabKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateSellItemDialog(context);
          } else {
            _showCreateLostItemDialog(context);
          }
        },
        icon: Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Sell Item' : 'Report Item'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCreateSellItemDialog(BuildContext context) {
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        final priceController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();
        List<XFile> selectedImages = [];
        String selectedCategory = 'Electronics';
        String selectedCondition = 'Good';

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.blue),
                SizedBox(width: 12),
                Text('Create Sell Item'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '฿',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'Electronics',
                                'Books',
                                'Clothing',
                                'Furniture',
                                'Sports',
                                'Other',
                              ]
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCondition,
                      decoration: InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: ['New', 'Like New', 'Good', 'Fair', 'Poor']
                          .map(
                            (cond) => DropdownMenuItem(
                              value: cond,
                              child: Text(cond),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCondition = val!),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Images (max 5)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_photo_alternate),
                          label: Text('Add Images'),
                          onPressed: selectedImages.length >= 5
                              ? null
                              : () async {
                                  final ImagePicker picker = ImagePicker();
                                  final List<XFile> images = await picker
                                      .pickMultiImage();
                                  if (images.isNotEmpty) {
                                    setState(() {
                                      // Add new images, but limit to 5 total
                                      int remainingSlots =
                                          5 - selectedImages.length;
                                      selectedImages.addAll(
                                        images.take(remainingSlots),
                                      );
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                    if (selectedImages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedImages
                              .asMap()
                              .entries
                              .map(
                                (entry) => Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          entry.value.path,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedImages.removeAt(entry.key);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (selectedImages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '${selectedImages.length} image(s) selected',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      descriptionController.text.isEmpty ||
                      priceController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    setState(() => errorMessage = 'Please fill all fields');
                    return;
                  }

                  setState(() => errorMessage = null);

                  try {
                    await SellItemService.createSellItem(
                      title: titleController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      category: selectedCategory,
                      condition: selectedCondition,
                      phone: phoneController.text,
                      email: emailController.text,
                      imageFiles: selectedImages.isEmpty
                          ? null
                          : selectedImages,
                    );
                    Navigator.pop(context);
                    _sellTabKey.currentState?._loadSellItems();
                  } catch (e) {
                    setState(() => errorMessage = 'Error: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateLostItemDialog(BuildContext context) {
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        final locationController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();
        List<XFile> selectedImages = [];
        String selectedCategory = 'Electronics';
        String selectedType = 'Lost';

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.find_in_page, color: Colors.orange),
                SizedBox(width: 12),
                Text('Report Lost/Found Item'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Lost', 'Found']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedType = val!),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'Electronics',
                                'Documents',
                                'Keys',
                                'Bags',
                                'Clothing',
                                'Jewelry',
                                'Books',
                                'Other',
                              ]
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Images (max 5)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_photo_alternate),
                          label: Text('Add Images'),
                          onPressed: selectedImages.length >= 5
                              ? null
                              : () async {
                                  final ImagePicker picker = ImagePicker();
                                  final List<XFile> images = await picker
                                      .pickMultiImage();
                                  if (images.isNotEmpty) {
                                    setState(() {
                                      // Add new images, but limit to 5 total
                                      int remainingSlots =
                                          5 - selectedImages.length;
                                      selectedImages.addAll(
                                        images.take(remainingSlots),
                                      );
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                    if (selectedImages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedImages
                              .asMap()
                              .entries
                              .map(
                                (entry) => Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          entry.value.path,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedImages.removeAt(entry.key);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (selectedImages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '${selectedImages.length} image(s) selected',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      descriptionController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    setState(() => errorMessage = 'Please fill all fields');
                    return;
                  }

                  setState(() => errorMessage = null);

                  try {
                    await LostItemService.createLostItem(
                      title: titleController.text,
                      description: descriptionController.text,
                      category: selectedCategory,
                      type: selectedType,
                      location: locationController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      imageFiles: selectedImages.isEmpty
                          ? null
                          : selectedImages,
                    );
                    Navigator.pop(context);
                    _lostTabKey.currentState?._loadLostItems();
                  } catch (e) {
                    setState(() => errorMessage = 'Error: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Report'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Sell Items Tab
class SellItemsTab extends StatefulWidget {
  const SellItemsTab({Key? key}) : super(key: key);

  @override
  _SellItemsTabState createState() => _SellItemsTabState();
}

class _SellItemsTabState extends State<SellItemsTab> {
  List<SellItem> _sellItems = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedStatus;
  String? _currentUserId;
  TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Electronics',
    'Books',
    'Clothing',
    'Furniture',
    'Sports',
    'Other',
  ];
  final List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];
  final List<String> _statuses = ['All', 'Available', 'Sold', 'Reserved'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSellItems();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.instance.getUserId();
      setState(() {
        _currentUserId = userId;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadSellItems() async {
    setState(() => _isLoading = true);
    try {
      final result = await SellItemService.getAllSellItems(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        condition: _selectedCondition == 'All' ? null : _selectedCondition,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _sellItems = result['items'] as List<SellItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _loadSellItems(),
              ),
              SizedBox(height: 8),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Category',
                      _selectedCategory,
                      _categories,
                    ),
                    SizedBox(width: 8),
                    _buildFilterChip(
                      'Condition',
                      _selectedCondition,
                      _conditions,
                    ),
                    SizedBox(width: 8),
                    _buildFilterChip('Status', _selectedStatus, _statuses),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _sellItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSellItems,
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _sellItems.length,
                    itemBuilder: (context, index) {
                      return _buildSellItemCard(_sellItems[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selected,
    List<String> options,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected ?? label),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor: selected != null ? Colors.blue[100] : Colors.white,
      ),
      onSelected: (value) {
        setState(() {
          if (label == 'Category') _selectedCategory = value;
          if (label == 'Condition') _selectedCondition = value;
          if (label == 'Status') _selectedStatus = value;
        });
        _loadSellItems();
      },
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  Widget _buildSellItemCard(SellItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDetails(item),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image, size: 40),
                        ),
                      )
                    : Icon(Icons.image, size: 40, color: Colors.grey[600]),
              ),
              SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '฿${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(item.condition, Colors.orange),
                        SizedBox(width: 4),
                        _buildTag(item.status, _getStatusColor(item.status)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Color.lerp(color, Colors.black, 0.6)!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Sold':
        return Colors.red;
      case 'Reserved':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteSellItem(SellItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SellItemService.deleteSellItem(item.id);
        Navigator.pop(context); // Close details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSellItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editSellItem(SellItem item) {
    Navigator.pop(context); // Close details dialog
    _showEditSellItemDialog(item);
  }

  void _showItemDetails(SellItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width * 0.95,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  item.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // Image gallery
                if (item.images.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.images.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _showFullImage(item.images, index),
                        child: Container(
                          width: 200,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                Text(
                  '฿${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildTag(item.category, Colors.blue),
                    SizedBox(width: 8),
                    _buildTag(item.condition, Colors.orange),
                    SizedBox(width: 8),
                    _buildTag(item.status, _getStatusColor(item.status)),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(item.description, style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.blue),
                  title: Text(item.contactInfo['phone'] ?? 'N/A'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text(item.contactInfo['email'] ?? 'N/A'),
                  dense: true,
                ),
                if (item.sellerName != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Seller',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(item.sellerName!, style: TextStyle(fontSize: 16)),
                ],
                // Edit and Delete buttons for owner
                if (_currentUserId != null &&
                    _currentUserId == item.sellerId) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editSellItem(item),
                          icon: Icon(Icons.edit),
                          label: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteSellItem(item),
                          icon: Icon(Icons.delete),
                          label: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  controller: PageController(initialPage: initialIndex),
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) => InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${images.length}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditSellItemDialog(SellItem item) {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final phoneController = TextEditingController(
      text: item.contactInfo['phone'],
    );
    final emailController = TextEditingController(
      text: item.contactInfo['email'],
    );
    List<XFile> selectedImages = [];
    List<String> keptImageUrls = List.from(item.images);
    String selectedCategory = item.category;
    String selectedCondition = item.condition;
    String selectedStatus = item.status;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Edit Sell Item',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                            prefixText: '฿',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'Electronics',
                                    'Books',
                                    'Clothing',
                                    'Furniture',
                                    'Sports',
                                    'Other',
                                  ]
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCategory = val!),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCondition,
                          decoration: InputDecoration(
                            labelText: 'Condition',
                            border: OutlineInputBorder(),
                          ),
                          items: ['New', 'Like New', 'Good', 'Fair', 'Poor']
                              .map(
                                (cond) => DropdownMenuItem(
                                  value: cond,
                                  child: Text(cond),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCondition = val!),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Available', 'Sold', 'Reserved']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedStatus = val!),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        if (item.images.isNotEmpty) ...[
                          Text(
                            'Current Images (${keptImageUrls.length}/${item.images.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.images
                                .map(
                                  (imageUrl) => Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                keptImageUrls.contains(imageUrl)
                                                ? Colors.blue
                                                : Colors.red.shade300,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Opacity(
                                            opacity:
                                                keptImageUrls.contains(imageUrl)
                                                ? 1.0
                                                : 0.4,
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (keptImageUrls.contains(
                                                imageUrl,
                                              )) {
                                                keptImageUrls.remove(imageUrl);
                                              } else {
                                                keptImageUrls.add(imageUrl);
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  keptImageUrls.contains(
                                                    imageUrl,
                                                  )
                                                  ? Colors.red
                                                  : Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              keptImageUrls.contains(imageUrl)
                                                  ? Icons.close
                                                  : Icons.undo,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Text(
                              'Add New Images (${selectedImages.length}/5)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add_photo_alternate),
                              label: Text('Add Images'),
                              onPressed: selectedImages.length >= 5
                                  ? null
                                  : () async {
                                      final ImagePicker picker = ImagePicker();
                                      final List<XFile> images = await picker
                                          .pickMultiImage();
                                      if (images.isNotEmpty) {
                                        setState(() {
                                          int remainingSlots =
                                              5 - selectedImages.length;
                                          selectedImages.addAll(
                                            images.take(remainingSlots),
                                          );
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                        if (selectedImages.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedImages
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              entry.value.path,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedImages.removeAt(
                                                  entry.key,
                                                );
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (selectedImages.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '${selectedImages.length} new image(s) to upload',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            titleController.dispose();
                            descriptionController.dispose();
                            priceController.dispose();
                            phoneController.dispose();
                            emailController.dispose();
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty ||
                                descriptionController.text.isEmpty ||
                                priceController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please fill in required fields',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              await SellItemService.updateSellItem(
                                item.id,
                                title: titleController.text,
                                description: descriptionController.text,
                                price: double.parse(priceController.text),
                                category: selectedCategory,
                                condition: selectedCondition,
                                status: selectedStatus,
                                phone: phoneController.text,
                                email: emailController.text,
                                keptImageUrls: keptImageUrls,
                                imageFiles: selectedImages.isEmpty
                                    ? null
                                    : selectedImages,
                              );

                              titleController.dispose();
                              descriptionController.dispose();
                              priceController.dispose();
                              phoneController.dispose();
                              emailController.dispose();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadSellItems();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lost and Found Tab
class LostAndFoundTab extends StatefulWidget {
  const LostAndFoundTab({Key? key}) : super(key: key);

  @override
  _LostAndFoundTabState createState() => _LostAndFoundTabState();
}

class _LostAndFoundTabState extends State<LostAndFoundTab> {
  List<LostItem> _lostItems = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedStatus;
  String? _currentUserId;
  TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Electronics',
    'Documents',
    'Keys',
    'Bags',
    'Clothing',
    'Jewelry',
    'Books',
    'Other',
  ];
  final List<String> _types = ['All', 'Lost', 'Found'];
  final List<String> _statuses = ['All', 'Active', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadLostItems();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.instance.getUserId();
      setState(() {
        _currentUserId = userId;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadLostItems() async {
    setState(() => _isLoading = true);
    try {
      final result = await LostItemService.getAllLostItems(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        type: _selectedType == 'All' ? null : _selectedType,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _lostItems = result['items'] as List<LostItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _loadLostItems(),
              ),
              SizedBox(height: 8),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Category',
                      _selectedCategory,
                      _categories,
                    ),
                    SizedBox(width: 8),
                    _buildFilterChip('Type', _selectedType, _types),
                    SizedBox(width: 8),
                    _buildFilterChip('Status', _selectedStatus, _statuses),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _lostItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.find_in_page_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLostItems,
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _lostItems.length,
                    itemBuilder: (context, index) {
                      return _buildLostItemCard(_lostItems[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selected,
    List<String> options,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected ?? label),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor: selected != null ? Colors.blue[100] : Colors.white,
      ),
      onSelected: (value) {
        setState(() {
          if (label == 'Category') _selectedCategory = value;
          if (label == 'Type') _selectedType = value;
          if (label == 'Status') _selectedStatus = value;
        });
        _loadLostItems();
      },
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  Widget _buildLostItemCard(LostItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDetails(item),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image, size: 40),
                        ),
                      )
                    : Icon(
                        item.type == 'Lost'
                            ? Icons.help_outline
                            : Icons.check_circle_outline,
                        size: 40,
                        color: Colors.grey[600],
                      ),
              ),
              SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(item.type, _getTypeColor(item.type)),
                        SizedBox(width: 4),
                        _buildTag(item.status, _getStatusColor(item.status)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Color.lerp(color, Colors.black, 0.6)!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    return type == 'Lost' ? Colors.red : Colors.green;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteLostItem(LostItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await LostItemService.deleteLostItem(item.id);
        Navigator.pop(context); // Close details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadLostItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editLostItem(LostItem item) {
    Navigator.pop(context); // Close details dialog
    _showEditLostItemDialog(item);
  }

  void _showItemDetails(LostItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width * 0.95,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  item.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // Image gallery
                if (item.images.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.images.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => _showFullImage(item.images, index),
                        child: Container(
                          width: 200,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                Row(
                  children: [
                    _buildTag(item.category, Colors.blue),
                    SizedBox(width: 8),
                    _buildTag(item.type, _getTypeColor(item.type)),
                    SizedBox(width: 8),
                    _buildTag(item.status, _getStatusColor(item.status)),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(item.description, style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  'Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.location_on, color: Colors.red),
                  title: Text(item.location),
                  dense: true,
                ),
                SizedBox(height: 8),
                Text(
                  'Date Reported',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${item.dateReported.day}/${item.dateReported.month}/${item.dateReported.year}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.blue),
                  title: Text(item.contactInfo['phone'] ?? 'N/A'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text(item.contactInfo['email'] ?? 'N/A'),
                  dense: true,
                ),
                if (item.reporterName != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Reporter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(item.reporterName!, style: TextStyle(fontSize: 16)),
                ],
                // Edit and Delete buttons for owner
                if (_currentUserId != null &&
                    _currentUserId == item.reporterId) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editLostItem(item),
                          icon: Icon(Icons.edit),
                          label: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteLostItem(item),
                          icon: Icon(Icons.delete),
                          label: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  controller: PageController(initialPage: initialIndex),
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) => InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${images.length}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditLostItemDialog(LostItem item) {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);
    final locationController = TextEditingController(text: item.location);
    final phoneController = TextEditingController(
      text: item.contactInfo['phone'],
    );
    final emailController = TextEditingController(
      text: item.contactInfo['email'],
    );
    List<XFile> selectedImages = [];
    List<String> keptImageUrls = List.from(item.images);
    String selectedCategory = item.category;
    String selectedType = item.type;
    String selectedStatus = item.status;
    DateTime selectedDate = item.dateReported;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Edit Lost/Found Item',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Lost', 'Found']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedType = val!),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'Electronics',
                                    'Documents',
                                    'Keys',
                                    'Bags',
                                    'Clothing',
                                    'Jewelry',
                                    'Books',
                                    'Other',
                                  ]
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCategory = val!),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Active', 'Resolved', 'Closed']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedStatus = val!),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        ListTile(
                          title: Text('Date Reported'),
                          subtitle: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        if (item.images.isNotEmpty) ...[
                          Text(
                            'Current Images (${keptImageUrls.length}/${item.images.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.images
                                .map(
                                  (imageUrl) => Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                keptImageUrls.contains(imageUrl)
                                                ? Colors.orange
                                                : Colors.red.shade300,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Opacity(
                                            opacity:
                                                keptImageUrls.contains(imageUrl)
                                                ? 1.0
                                                : 0.4,
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (keptImageUrls.contains(
                                                imageUrl,
                                              )) {
                                                keptImageUrls.remove(imageUrl);
                                              } else {
                                                keptImageUrls.add(imageUrl);
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  keptImageUrls.contains(
                                                    imageUrl,
                                                  )
                                                  ? Colors.red
                                                  : Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              keptImageUrls.contains(imageUrl)
                                                  ? Icons.close
                                                  : Icons.undo,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Text(
                              'Add New Images (${selectedImages.length}/5)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add_photo_alternate),
                              label: Text('Add Images'),
                              onPressed: selectedImages.length >= 5
                                  ? null
                                  : () async {
                                      final ImagePicker picker = ImagePicker();
                                      final List<XFile> images = await picker
                                          .pickMultiImage();
                                      if (images.isNotEmpty) {
                                        setState(() {
                                          int remainingSlots =
                                              5 - selectedImages.length;
                                          selectedImages.addAll(
                                            images.take(remainingSlots),
                                          );
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                        if (selectedImages.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedImages
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              entry.value.path,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedImages.removeAt(
                                                  entry.key,
                                                );
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (selectedImages.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '${selectedImages.length} new image(s) to upload',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            titleController.dispose();
                            descriptionController.dispose();
                            locationController.dispose();
                            phoneController.dispose();
                            emailController.dispose();
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty ||
                                descriptionController.text.isEmpty ||
                                locationController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please fill in required fields',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              await LostItemService.updateLostItem(
                                item.id,
                                title: titleController.text,
                                description: descriptionController.text,
                                category: selectedCategory,
                                type: selectedType,
                                status: selectedStatus,
                                location: locationController.text,
                                phone: phoneController.text,
                                email: emailController.text,
                                keptImageUrls: keptImageUrls,
                                imageFiles: selectedImages.isEmpty
                                    ? null
                                    : selectedImages,
                              );

                              titleController.dispose();
                              descriptionController.dispose();
                              locationController.dispose();
                              phoneController.dispose();
                              emailController.dispose();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadLostItems();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
