import 'package:flutter/material.dart';
import '../widgets/info_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InfoScreen extends StatelessWidget {

  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              appLocalizations.infoScreenTitle,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                InfoCard(
                  icon: Icons.people,
                  title: appLocalizations.whoAreWeTitle,
                  subtitle: appLocalizations.whoAreWeSubtitle,
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 20),
                InfoCard(
                  icon: Icons.timer_sharp,
                  title: appLocalizations.whoIsItUsefulForTitle,
                  subtitle: appLocalizations.whoIsItUsefulForSubtitle,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 20),
                InfoCard(
                  icon: Icons.app_shortcut,
                  title: appLocalizations.whyDidWeMakeThisAppTitle,
                  subtitle: appLocalizations.whyDidWeMakeThisAppSubtitle,
                  iconColor: Colors.purple,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    appLocalizations.copyrightText,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
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