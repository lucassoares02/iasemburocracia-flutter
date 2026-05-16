import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CardCompany extends StatefulWidget {
  const CardCompany({
    super.key,
    this.cep,
    this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.bairro,
    this.logradouro,
    this.numero,
    this.municipio,
    this.uf,
    this.icon,
  });

  final String? cep;
  final String? cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? bairro;
  final String? logradouro;
  final String? numero;
  final String? municipio;
  final String? uf;
  final IconData? icon;

  @override
  State<CardCompany> createState() => _CardCompanyState();
}

class _CardCompanyState extends State<CardCompany> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                widget.icon ?? LucideIcons.check,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.cnpj ?? ''} - ${widget.razaoSocial ?? ''}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.logradouro ?? ''}, ${widget.numero ?? ''} - ${widget.bairro ?? ''}, ${widget.municipio ?? ''} - ${widget.uf ?? ''}, CEP: ${widget.cep ?? ''}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
