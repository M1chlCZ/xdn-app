import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../support/ColorScheme.dart';
import '../models/Contact.dart';
import '../widgets/AvatarPicker.dart';


class ContactTile extends StatelessWidget {
  final Contact? contact;
  final void Function(int id)? func;
  final void Function(String name, String addr, Contact c)? func2;
  final void Function(Contact c)? func3;

  const ContactTile({Key? key, this.contact, this.func, this.func2, this.func3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 0.0, top: 4.0),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 0,
        color: const Color(0xFF181C2A).withOpacity(0.3),
        child: InkWell(
          splashColor: Theme.of(context).konjCardColor,
          onTap: () {
            func2!(contact!.name!, contact!.addr!, contact!);
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 3.0),
                child: AvatarPicker(userID: contact!.addr!,
                  avatarColor: Colors.white54,
                  color: const Color(0xFF22304D),
                  size: 60.0, padding: 2.0,),
              ),
              Column(children: [
                Padding(
                  padding: const EdgeInsets.only(left: 70.0, right: 0.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            contact!.name!,
                            style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70, fontSize: 18.0, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                                onTap: () {
                                  func3!(contact!);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    // border: Border.all(color: Colors.amber),
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10.0),
                                    ),
                                  ),
                                  child: Icon(Icons.edit,
                                      color: Colors.white70.withOpacity(0.8)),
                                )),
                            GestureDetector(
                                onTap: () {
                                  func!(contact!.id!);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    // border: Border.all(color: Colors.amber),
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(10.0)
                                    ),
                                  ),
                                  child: Icon(Icons.delete,
                                      color: Colors.white.withOpacity(0.8)),
                                )),
                          ],
                        ),
                      ]),
                ),
                const SizedBox(
                  height: 4,
                ),
                Padding(
                  padding: const EdgeInsets.only(left:65.0, right: 20.0),
                  child: SizedBox(
                    width: 260,
                    child: AutoSizeText(
                      contact!.addr!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white70, fontSize: 16.0),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                )
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
