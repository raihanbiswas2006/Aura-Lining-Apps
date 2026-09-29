import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/search/search_cubit.dart';

class SearchModal extends StatefulWidget {
  final void Function(String query) onSearchSubmitted;
  final void Function(Product product) onProductSelected;

  const SearchModal({
    super.key,
    required this.onSearchSubmitted,
    required this.onProductSelected,
  });

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<SearchCubit>().recordSearch(query.trim());
    Navigator.of(context).pop();
    widget.onSearchSubmitted(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: AppTypography.bodyLarge,
          textInputAction: TextInputAction.search,
          onSubmitted: _submitSearch,
          onChanged: (val) {
            context.read<SearchCubit>().onQueryChanged(val);
          },
          decoration: InputDecoration(
            hintText: 'Search furniture, lighting, linen...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchCubit>().onQueryChanged('');
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            );
          }

          if (state.isZeroState) {
            return _buildZeroState(context, state);
          }

          return _buildResultsState(context, state);
        },
      ),
    );
  }

  Widget _buildZeroState(BuildContext context, SearchState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Recent searches section
        if (state.recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEARCHES',
                style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () {
                  context.read<SearchCubit>().clearRecentSearches();
                },
                child: Text(
                  'Clear All',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...state.recentSearches.map((term) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, size: 18, color: AppColors.textMuted),
              title: Text(term, style: AppTypography.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                onPressed: () {
                  context.read<SearchCubit>().removeRecentSearch(term);
                },
              ),
              onTap: () {
                _controller.text = term;
                _submitSearch(term);
              },
            );
          }),
          const SizedBox(height: 24),
        ],

        // Popular Searches section
        Text(
          'POPULAR SEARCHES',
          style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.popularSearches.map((term) {
            return ActionChip(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              label: Text(
                term,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () {
                _controller.text = term;
                _submitSearch(term);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsState(BuildContext context, SearchState state) {
    if (state.suggestedTerms.isEmpty && state.matchingProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No results found for "${state.query}"',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spelling, try broader search terms, or explore popular categories.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Suggested Terms
        if (state.suggestedTerms.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'SUGGESTIONS',
              style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ...state.suggestedTerms.map((term) {
            return ListTile(
              leading: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              title: Text(term, style: AppTypography.bodyMedium),
              trailing: const Icon(Icons.north_west, size: 14, color: AppColors.textMuted),
              onTap: () {
                _controller.text = term;
                _submitSearch(term);
              },
            );
          }),
          const Divider(height: 24),
        ],

        // Matching Products
        if (state.matchingProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'MATCHING PIECES',
              style: AppTypography.overline.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ...state.matchingProducts.map((product) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.surfaceSecondary,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              title: Text(
                product.title,
                style: AppTypography.titleSmall.copyWith(fontSize: 14),
              ),
              subtitle: Text(
                product.brand,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              trailing: Text(
                CurrencyFormatter.format(product.price),
                style: AppTypography.price.copyWith(fontSize: 14),
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.onProductSelected(product);
              },
            );
          }),
        ],
      ],
    );
  }
}
