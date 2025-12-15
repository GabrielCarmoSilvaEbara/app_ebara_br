import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productName;
  final String category;
  final String imageUrl;

  const ProductDetailsPage({
    super.key,
    required this.productName,
    required this.category,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductTitle(),
                          const SizedBox(height: 16),
                          _buildDescription(),
                          const SizedBox(height: 24),
                          _buildApplicationsSection(),
                          const SizedBox(height: 24),
                          _buildTechnicalInfoSection(),
                          const SizedBox(height: 32),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                category,
                style: AppTextStyles.text1.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.all(20),
      child: Image.asset(imageUrl, fit: BoxFit.contain),
    );
  }

  Widget _buildProductTitle() {
    return Text(productName, style: AppTextStyles.text.copyWith(fontSize: 32));
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motobomba Centrífuga Monoestágio - Monobloco - Motor Monofásico em II Polos, 60Hz, 3500rpm - Bocais com rosca BSP, Sucção 3/4" x Recalque 3/4".',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Utilizada para água limpa até temperatura de 40ºC (Temperaturas superiores, consultar opções).',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Carcaça da bomba em ferro fundido GG-20.',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Rotor fechado em termoplástico. Anel O\'ring de vedação da carcaça em Buna N.',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Selo mecânico: Faces em grafite e cerâmica.',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Mola em inox 304 e elastômero (borracha) em Buna N.',
          style: AppTextStyles.text4.copyWith(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aplicações', style: AppTextStyles.text.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildApplicationIcon(Icons.home),
            _buildApplicationIcon(Icons.business),
            _buildApplicationIcon(Icons.local_drink),
            _buildApplicationIcon(Icons.grass),
            _buildApplicationIcon(Icons.water_drop),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicationIcon(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildTechnicalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações Técnicas',
          style: AppTextStyles.text.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        _buildTechnicalInfoRow('Potência', '0.5 cv'),
        const SizedBox(height: 12),
        _buildTechnicalInfoRow('Voltagem', '127/220-254 V'),
      ],
    );
  }

  Widget _buildTechnicalInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.text1.copyWith(
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.text4.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
