import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/service_types/bloc/service_types_bloc.dart';
import 'package:hudhud_delivery/features/service_types/data/data_provider/service_types_data_provider.dart';
import 'package:hudhud_delivery/features/service_types/data/repository/service_types_repository.dart';
import 'package:hudhud_delivery/features/service_types/model/service_type_model.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static IconData _iconForServiceCode(String code) {
    switch (code.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_basket;
      case 'handyman':
        return Icons.handyman;
      case 'messenger':
        return Icons.local_shipping;
      case 'restaurant':
        return Icons.restaurant;
      case 'ride_hailing':
        return Icons.local_taxi;
      case 'supermarket':
        return Icons.store;
      case 'food_delivery':
        return Icons.delivery_dining;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ServiceTypesRepository(
      dataProvider: ServiceTypesDataProvider(apiService: ApiService.instance),
    );
    return BlocProvider(
      create: (context) =>
          ServiceTypesBloc(repository)..add(FetchServiceTypesEvent()),
      child: const _ServicesScreenBody(),
    );
  }
}

class _ServicesScreenBody extends StatelessWidget {
  const _ServicesScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ServiceTypesBloc, ServiceTypesState>(
        builder: (context, state) {
          if (state is ServiceTypesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ServiceTypesFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ServiceTypesBloc>()
                          .add(FetchServiceTypesEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ServiceTypesSuccess) {
            final serviceTypes = state.serviceTypes;
            if (serviceTypes.isEmpty) {
              return const Center(child: Text('No services available.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: serviceTypes.length,
              itemBuilder: (context, index) {
                final service = serviceTypes[index];
                return _ServiceTypeGridItem(service: service);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ServiceTypeGridItem extends StatelessWidget {
  final ServiceTypeModel service;

  const _ServiceTypeGridItem({required this.service});

  @override
  Widget build(BuildContext context) {
    final icon = ServicesScreen._iconForServiceCode(service.code);
    final iconUrl = service.iconUrl;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to service-specific flow
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconUrl != null && iconUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  iconUrl,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    icon,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 32,
                color: AppColors.primaryColor,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  service.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
