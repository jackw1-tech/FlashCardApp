import 'package:flashcard/state_management/cubits/card_actions_cubit/card_actions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CardActionsListener extends StatelessWidget {
  final Widget child;

  const CardActionsListener({required this.child, super.key});

  @override
  Widget build(BuildContext context) =>
      BlocListener<CardActionsCubit, CardActionsState>(
        listenWhen: (previous, current) =>
            current.sequence != previous.sequence && current.message != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message!))),
        child: child,
      );
}
