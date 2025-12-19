import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/admin_controller.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class AdminProductManagementScreen extends StatefulWidget {
  const AdminProductManagementScreen({super.key});

  @override
  State<AdminProductManagementScreen> createState() =>
      _AdminProductManagementScreenState();
}

class _AdminProductManagementScreenState
    extends State<AdminProductManagementScreen> {
  final _productService = Get.find<ProductService>();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.fetchProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    File? selectedImage;
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Produk Baru'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Harga wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Produk',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan deskripsi produk...',
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (selectedImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.grey,
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                        ),
                        if (selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'File dipilih: ${selectedImage!.path.split('/').last}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (selectedImage == null) {
                    Get.snackbar('Error', 'Pilih gambar terlebih dahulu');
                    return;
                  }

                  final adminController = Get.find<AdminController>();
                  final product = Product(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    image: selectedImage!.path,
                    description: descriptionController.text,
                  );

                  Navigator.pop(context);
                  final success = await adminController.addProduct(product);
                  if (success) {
                    _loadProducts();
                  }
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final descriptionController = TextEditingController(
      text: product.description,
    );
    final formKey = GlobalKey<FormState>();
    File? selectedImage;
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            child: AlertDialog(
              title: const Text('Edit Produk'),
              content: SizedBox(
                width: 350,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Harga wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Produk',
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan deskripsi produk...',
                            isDense: true,
                          ),
                          maxLines: 3,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Deskripsi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : product.isAssetImage
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          product.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              ),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final XFile? image = await imagePicker
                                        .pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = File(image.path);
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 16),
                                  label: const Text(
                                    'Pilih Gambar',
                                    style: TextStyle(fontSize: 12),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final adminController = Get.find<AdminController>();

                      String imageToUse = product.image;
                      if (selectedImage != null) {
                        imageToUse = selectedImage!.path;
                      }

                      final updatedProduct = Product(
                        id: product.id,
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        image: imageToUse,
                        description: descriptionController.text,
                      );

                      Navigator.pop(context);
                      final success = await adminController.updateProduct(
                        updatedProduct,
                      );
                      if (success) {
                        _loadProducts();
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final adminController = Get.find<AdminController>();
              final success = await adminController.deleteProduct(product.id);
              if (success) {
                _loadProducts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Produk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? const Center(child: Text('Belum ada produk'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.isAssetImage
                                  ? Image.asset(
                                      product.image,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image),
                                    )
                                  : Image.network(
                                      product.image,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image),
                                    ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Edit Produk',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    onPressed: () =>
                                        _showEditProductDialog(product),
                                    splashRadius: 24,
                                  ),
                                ),
                                Tooltip(
                                  message: 'Hapus Produk',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmation(product),
                                    splashRadius: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
