import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:islamy/engines/hadeeth/models/hadeeth.dart';

class HadeethTile extends StatelessWidget {
  const HadeethTile({required this.hadeeth, super.key});
  final Hadeeth hadeeth;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        hadeeth.title,
        maxLines: 2,
        overflow: TextOverflow.fade,
      ),
      trailing: const Icon(CupertinoIcons.forward),
      onTap: () {
        // Navigator.of(context).pushNamed(
        //   'hadeeth_details',
        //   arguments: <String, Object?>{
        //     'category': hadeeth,
        //   },
        // );
      },
    );
  }
}