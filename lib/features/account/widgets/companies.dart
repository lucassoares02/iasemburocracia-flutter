// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:portal_assoc/core/state/app_state.dart';
// import 'package:portal_assoc/core/utils/format_currency.dart';
// import 'package:portal_assoc/core/utils/spacing.dart';
// import 'package:portal_assoc/features/account/account_controller.dart';
// import 'package:portal_assoc/features/account/widgets/base_account.dart';
// import 'package:portal_assoc/features/register/companies_model.dart';
// import 'package:portal_assoc/shared/widgets/loading_container.dart';
// import 'package:portal_assoc/shared/widgets/special_button.dart';

// class Companies extends StatefulWidget {
//   const Companies({super.key, required this.controller});

//   final AccountController controller;

//   @override
//   State<Companies> createState() => _CompaniesState();
// }

// class _CompaniesState extends State<Companies> {
//   bool _isEditing = false;
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _cnpjController;
//   late TextEditingController _razaoSocialController;
//   late TextEditingController _nomeFantasiaController;
//   late TextEditingController _logradouroController;
//   late TextEditingController _numeroController;
//   late TextEditingController _bairroController;
//   late TextEditingController _municipioController;
//   late TextEditingController _ufController;
//   late TextEditingController _emailController;

//   CompaniesModel? _currentCompany;

//   @override
//   void initState() {
//     widget.controller.findCompanyId();
//     _cnpjController = TextEditingController();
//     _razaoSocialController = TextEditingController();
//     _nomeFantasiaController = TextEditingController();
//     _logradouroController = TextEditingController();
//     _numeroController = TextEditingController();
//     _bairroController = TextEditingController();
//     _municipioController = TextEditingController();
//     _ufController = TextEditingController();
//     _emailController = TextEditingController();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _cnpjController.dispose();
//     _razaoSocialController.dispose();
//     _nomeFantasiaController.dispose();
//     _logradouroController.dispose();
//     _numeroController.dispose();
//     _bairroController.dispose();
//     _municipioController.dispose();
//     _ufController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }

//   void _initializeControllers(CompaniesModel company) {
//     _currentCompany = company;
//     _cnpjController.text = company.cnpj ?? '';
//     _razaoSocialController.text = company.razaoSocial ?? '';
//     _nomeFantasiaController.text = company.nomeFantasia ?? '';
//     _logradouroController.text = company.logradouro ?? '';
//     _numeroController.text = company.numero ?? '';
//     _bairroController.text = company.bairro ?? '';
//     _municipioController.text = company.municipio ?? '';
//     _ufController.text = company.uf ?? '';
//     _emailController.text = company.email ?? '';
//   }

//   void _toggleEditMode() {
//     setState(() {
//       _isEditing = !_isEditing;
//       if (!_isEditing && _currentCompany != null) {
//         _initializeControllers(_currentCompany!);
//       }
//     });
//   }

//   Future<void> _saveChanges() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       final updatedCompany = CompaniesModel.fromJson({
//         "nome_fantasia": _nomeFantasiaController.text,
//         "id": _currentCompany?.id,
//       });

//       await widget.controller.updateCompany(updatedCompany);

//       setState(() {
//         _isEditing = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BaseAccount(
//       title: "Minha empresa",
//       child: Expanded(
//         child: Column(
//           children: [
//             Expanded(
//               child: ValueListenableBuilder(
//                 valueListenable: widget.controller.stateFindCompanies,
//                 builder: (context, state, _) {
//                   if (state is LoadingState) {
//                     return _buildLoadingSkeleton();
//                   } else if (state is ErrorState) {
//                     return _buildErrorState(state.message);
//                   } else if (state is SuccessState) {
//                     if (state.data.isEmpty) {
//                       return _buildEmptyState();
//                     }
//                     CompaniesModel company = state.data[0];
//                     if (_currentCompany == null || !_isEditing) {
//                       _initializeControllers(company);
//                     }
//                     return _buildCompanyContent(company);
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingSkeleton() {
//     return const Padding(
//       padding: EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               LoadingContainer(height: 80, width: 80),
//               SizedBox(width: 24),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     LoadingContainer(height: 24, width: 250),
//                     SizedBox(height: 8),
//                     LoadingContainer(
//                       height: 16,
//                       width: 180,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 32),
//           LoadingContainer(height: 120, width: double.infinity),
//           SizedBox(height: 16),
//           LoadingContainer(height: 120, width: double.infinity),
//           SizedBox(height: 16),
//           LoadingContainer(height: 100, width: double.infinity),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red[300],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "Erro ao carregar empresas",
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             OutlinedButton.icon(
//               onPressed: () => widget.controller.findCompanyId(),
//               icon: const Icon(Icons.refresh),
//               label: const Text("Tentar novamente"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.business_outlined,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "Nenhuma empresa cadastrada",
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Adicione uma empresa para começar",
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCompanyContent(CompaniesModel company) {
//     return Column(
//       children: [
//         // Conteúdo scrollável
//         Expanded(
//           child: ScrollConfiguration(
//             behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header da empresa
//                     _buildCompanyHeader(company),

//                     const Spacing(),
//                     Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
//                     const Spacing(),
//                     // Informações da empresa
//                     _buildInfoSection(
//                       title: "Informações da Empresa",
//                       icon: Icons.business,
//                       children: [
//                         _buildInfoRow(
//                           icon: Icons.badge_outlined,
//                           type: company.type,
//                           label: "CNPJ",
//                           value: _formatCNPJ(company.cnpj) ?? "Não informado",
//                           controller: _cnpjController,
//                           isEditable: false,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'CNPJ é obrigatório';
//                             }
//                             return null;
//                           },
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.business_center,
//                           label: "Razão Social",
//                           value: company.razaoSocial ?? "Não informado",
//                           controller: _razaoSocialController,
//                           isEditable: false,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Razão Social é obrigatória';
//                             }
//                             return null;
//                           },
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.storefront,
//                           label: "Nome Fantasia",
//                           value: company.nomeFantasia ?? "Não informado",
//                           controller: _nomeFantasiaController,
//                           isEditable: true,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 24),

//                     // Endereço
//                     _buildInfoSection(
//                       title: "Endereço",
//                       icon: Icons.location_on,
//                       children: [
//                         _buildInfoRow(
//                           icon: Icons.route,
//                           label: "Logradouro",
//                           value: company.logradouro ?? "Não informado",
//                           controller: _logradouroController,
//                           isEditable: false,
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.pin,
//                           label: "Número",
//                           value: company.numero ?? "Não informado",
//                           controller: _numeroController,
//                           isEditable: false,
//                           keyboardType: TextInputType.number,
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.map,
//                           label: "Bairro",
//                           value: company.bairro ?? "Não informado",
//                           controller: _bairroController,
//                           isEditable: false,
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.location_city,
//                           label: "Cidade",
//                           value: company.municipio ?? "Não informado",
//                           controller: _municipioController,
//                           isEditable: false,
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.flag,
//                           label: "Estado",
//                           value: company.uf ?? "Não informado",
//                           controller: _ufController,
//                           isEditable: false,
//                         ),
//                       ],
//                     ),

//                     // const SizedBox(height: 24),

//                     // Contato
//                     // _buildInfoSection(
//                     //   title: "Contato",
//                     //   icon: Icons.contact_mail,
//                     //   children: [
//                     //     _buildInfoRow(
//                     //       icon: Icons.email_outlined,
//                     //       label: "E-mail",
//                     //       value: company.email ?? "Não informado",
//                     //       controller: _emailController,
//                     //       isEditable: true,
//                     //       keyboardType: TextInputType.emailAddress,
//                     //       validator: (value) {
//                     //         if (value != null && value.isNotEmpty) {
//                     //           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                     //             return 'E-mail inválido';
//                     //           }
//                     //         }
//                     //         return null;
//                     //       },
//                     //     ),
//                     //   ],
//                     // ),

//                     const SizedBox(height: 24),

//                     // Mais Informações
//                     _buildInfoSection(
//                       title: "Informações Adicionais",
//                       icon: Icons.info,
//                       children: [
//                         _buildInfoRow(
//                           icon: Icons.category,
//                           label: "Natureza Jurídica",
//                           value: "${company.codigoNaturezaJuridica ?? ''} - ${company.naturezaJuridica ?? 'Não informado'}",
//                           isEditable: false,
//                         ),
//                         _buildInfoRow(
//                           icon: Icons.account_balance,
//                           label: "Capital Social",
//                           value: formatCurrency(double.parse(company.capitalSocial.toString())),
//                           isEditable: false,
//                         ),
//                         _buildInfoRowWithCustomValue(
//                           icon: Icons.verified_outlined,
//                           label: "Situação Cadastral",
//                           customValue: _buildStatusBadge(company.descricaoSituacaoCadastral ?? ""),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCompanyHeader(CompaniesModel company) {
//     return Row(
//       children: [
//         // Ícone da empresa
//         Container(
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).primaryColor,
//                 Theme.of(context).primaryColor.withValues(alpha: 0.7),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: const Center(
//             child: Icon(
//               Icons.business,
//               size: 40,
//               color: Colors.white,
//             ),
//           ),
//         ),

//         const SizedBox(width: 24),

//         // Informações principais
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     (company.nomeFantasia != null && company.nomeFantasia != "") ? company.nomeFantasia.toString() : company.razaoSocial ?? "Não informado",
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w700,
//                         ),
//                   ),
//                   // Row(
//                   //   children: [
//                   //     if (_isEditing) ...[
//                   //       TextButton(
//                   //         style: TextButton.styleFrom(
//                   //           foregroundColor: Colors.grey[600],
//                   //         ),
//                   //         onPressed: _toggleEditMode,
//                   //         child: const Text("Cancelar"),
//                   //       ),
//                   //       const Spacing(),
//                   //     ],
//                   //     TextButton.icon(
//                   //       onPressed: _isEditing ? _saveChanges : _toggleEditMode,
//                   //       label: Text(_isEditing ? "Salvar" : "Editar"),
//                   //       icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit2),
//                   //     ),
//                   //   ],
//                   // )
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.badge_outlined,
//                     size: 16,
//                     color: Colors.grey[600],
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     _formatCNPJ(company.cnpj) ?? "CNPJ não disponível",
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Colors.grey[600],
//                         ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               _buildStatusBadge(company.descricaoSituacaoCadastral ?? ""),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoSection({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               title,
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[800],
//                   ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[200]!),
//           ),
//           child: Column(
//             children: _intersperse(
//               children,
//               Divider(height: 1, color: Colors.grey[200]),
//             ).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   List<Widget> _intersperse(List<Widget> list, Widget separator) {
//     if (list.isEmpty) return list;

//     final result = <Widget>[];
//     for (var i = 0; i < list.length; i++) {
//       result.add(list[i]);
//       if (i < list.length - 1) {
//         result.add(separator);
//       }
//     }
//     return result;
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     int? type,
//     bool isEditable = false,
//     TextEditingController? controller,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 20,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 8),
//                 if (_isEditing && isEditable && controller != null)
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: controller,
//                           keyboardType: keyboardType,
//                           validator: validator,
//                           decoration: InputDecoration(
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                 color: Theme.of(context).primaryColor,
//                                 width: 2,
//                               ),
//                             ),
//                             errorBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Colors.red),
//                             ),
//                           ),
//                           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                                 fontWeight: FontWeight.w500,
//                               ),
//                         ),
//                       ),
//                       const Spacing(),
//                       SpecialButton(
//                           color: Theme.of(context).colorScheme.primary,
//                           icon: LucideIcons.check,
//                           label: "Salvar",
//                           onPressButton: () {
//                             _saveChanges();
//                           })
//                     ],
//                   )
//                 else
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         value,
//                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                               fontWeight: FontWeight.w500,
//                             ),
//                       ),
//                       if (isEditable)
//                         InkWell(
//                           onTap: () {
//                             setState(() {
//                               _isEditing = true;
//                             });
//                           },
//                           child: const Icon(
//                             LucideIcons.edit2,
//                             size: 16,
//                           ),
//                         ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//           if (type != null && !_isEditing)
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: type == 2 ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     type == 2 ? LucideIcons.store : LucideIcons.shoppingCart,
//                     size: 16,
//                     color: type == 2 ? Colors.blue : Colors.green,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     type == 2 ? "Habilitado para vender" : "Habilitado para comprar",
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: type == 2 ? Colors.blue : Colors.green,
//                           fontWeight: FontWeight.w600,
//                         ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRowWithCustomValue({
//     required IconData icon,
//     required String label,
//     required Widget customValue,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 20,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//                 const SizedBox(height: 8),
//                 customValue,
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusBadge(String status) {
//     final isActive = status.toLowerCase().contains('ativa') || status.toLowerCase().contains('regular');

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: isActive ? Colors.green[50] : Colors.orange[50],
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isActive ? Colors.green[200]! : Colors.orange[200]!,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: isActive ? Colors.green : Colors.orange,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             status.isEmpty ? "Não informado" : status,
//             style: TextStyle(
//               color: isActive ? Colors.green[700] : Colors.orange[700],
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String? _formatCNPJ(String? cnpj) {
//     if (cnpj == null || cnpj.isEmpty) return null;
//     // Remover caracteres não numéricos
//     String numbers = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

//     if (numbers.length != 14) return cnpj;

//     // Formatar: 00.000.000/0000-00
//     return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12, 14)}';
//   }
// }
