import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../services/location_service.dart';
import '../../services/salon_service.dart';
import '../../models/salon_model.dart';
import '../salon/salon_detail_screen.dart';
import '../../widgets/salon_card.dart';

class MapScreen extends StatefulWidget {
  final SalonModel? initialSalon;
  
  const MapScreen({
    Key? key,
    this.initialSalon,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final SalonService _salonService = SalonService();
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<SalonModel> _allSalons = [];
  List<SalonModel> _filteredSalons = [];
  
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  double _selectedDistance = 10.0; // km
  String _selectedCategory = 'Tümü';
  bool _showOnlyOpen = false;
  
  final List<String> _categories = [
    'Tümü',
    'Kuaför',
    'Berber',
    'Güzellik Merkezi',
    'Spa & Wellness',
    'Nail Studio'
  ];

  // İstanbul Taksim koordinatları (varsayılan konum)
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(41.0370, 28.9857),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadSalons();
    _getCurrentLocation();
    
    // Eğer belirli bir salon için açıldıysa, o salonu vurgula
    if (widget.initialSalon != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnSalon(widget.initialSalon!);
      });
    }
  }

  void _focusOnSalon(SalonModel salon) {
    if (_mapController != null && salon.latitude != 0 && salon.longitude != 0) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(salon.latitude, salon.longitude),
            zoom: 16,
          ),
        ),
      );
      
      // Salon bilgilerini göster
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSalonBottomSheet(salon);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      print('🗺️ Konum alınıyor...');
      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        print('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
        
        // Haritayı kullanıcının konumuna odakla
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14,
              ),
            ),
          );
        }
        
        _filterSalonsByDistance();
      } else {
        print('❌ Konum alınamadı');
        _showLocationError();
      }
    } catch (e) {
      print('❌ Konum hatası: $e');
      _showLocationError();
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Konum bilgisi alınamadı. Varsayılan konum gösteriliyor.'),
        action: SnackBarAction(
          label: 'Tekrar Dene',
          onPressed: _getCurrentLocation,
        ),
      ),
    );
  }

  Future<void> _loadSalons() async {
    try {
      print('🗺️ Salonlar yükleniyor...');
      final salons = await _salonService.getAllSalons();
      
      setState(() {
        _allSalons = salons;
        _filteredSalons = salons;
        _isLoading = false;
      });
      
      print('✅ ${salons.length} salon yüklendi');
      _updateMarkers();
    } catch (e) {
      print('❌ Salon yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    if (_filteredSalons.isEmpty) return;

    Set<Marker> markers = {};
    
    // Kullanıcı konumu markeri
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Konumunuz',
            snippet: 'Mevcut konum',
          ),
        ),
      );
    }

    // Salon markerleri
    for (SalonModel salon in _filteredSalons) {
      if (salon.latitude != 0 && salon.longitude != 0) {
        markers.add(
          Marker(
            markerId: MarkerId(salon.id),
            position: LatLng(salon.latitude, salon.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              salon.isOpenNow ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
            ),
            infoWindow: InfoWindow(
              title: salon.name,
              snippet: '${salon.rating}⭐ • ${_getDistanceText(salon)}',
              onTap: () {
                _showSalonBottomSheet(salon);
              },
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  String _getDistanceText(SalonModel salon) {
    if (_currentPosition == null) return '';
    
    final distance = salon.calculateDistance(
      _currentPosition!.latitude, 
      _currentPosition!.longitude
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  void _filterSalonsByDistance() {
    if (_currentPosition == null) {
      setState(() {
        _filteredSalons = _allSalons.where(_applyFilters).toList();
      });
      _updateMarkers();
      return;
    }

    List<SalonModel> filtered = _allSalons.where((salon) {
      // Mesafe filtresi
      final distance = salon.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      return distance <= _selectedDistance && _applyFilters(salon);
    }).toList();

    // Mesafeye göre sırala
    filtered.sort((a, b) {
      final distanceA = a.calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude);
      final distanceB = b.calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude);
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _filteredSalons = filtered;
    });
    _updateMarkers();
  }

  bool _applyFilters(SalonModel salon) {
    // Kategori filtresi
    if (_selectedCategory != 'Tümü' && salon.category != _selectedCategory) {
      return false;
    }

    // Açık olanlar filtresi
    if (_showOnlyOpen && !salon.isOpenNow) {
      return false;
    }

    return true;
  }

  void _showSalonBottomSheet(SalonModel salon) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SalonCard(
              salon: salon,
              showDistance: _currentPosition != null,
              userLatitude: _currentPosition?.latitude,
              userLongitude: _currentPosition?.longitude,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalonDetailScreen(salon: salon),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDirections(salon);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Yol Tarifi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalonDetailScreen(salon: salon),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detaylar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDirections(SalonModel salon) {
    // Google Maps'te yol tarifi aç
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${salon.name} için yol tarifi özelliği yakında eklenecek'),
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Filtreleme Seçenekleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Mesafe filtresi
              Text(
                'Maksimum Mesafe: ${_selectedDistance.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _selectedDistance,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_selectedDistance.toStringAsFixed(0)} km',
                onChanged: (value) {
                  setModalState(() {
                    _selectedDistance = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Kategori filtresi
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Açık olanlar filtresi
              CheckboxListTile(
                title: const Text('Sadece açık olanları göster'),
                value: _showOnlyOpen,
                onChanged: (value) {
                  setModalState(() {
                    _showOnlyOpen = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // Uygula butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Filtreler zaten modal içinde güncellendi
                    });
                    Navigator.pop(context);
                    _filterSalonsByDistance();
                  },
                  child: const Text('Filtreleri Uygula'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: _isLoadingLocation 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Salonlar yükleniyor...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    
                    // Eğer kullanıcı konumu varsa oraya odakla
                    if (_currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            zoom: 14,
                          ),
                        ),
                      );
                    }
                  },
                  initialCameraPosition: _defaultLocation,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                
                // Salon sayısı göstergesi
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_filteredSalons.length} salon',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 