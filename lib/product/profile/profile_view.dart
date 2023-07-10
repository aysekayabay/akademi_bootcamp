import 'package:akademi_bootcamp/core/base/state/base_state.dart';
import 'package:akademi_bootcamp/core/constants/navigation/navigation_constants.dart';
import 'package:akademi_bootcamp/core/init/navigation/navigation_service.dart';
import 'package:akademi_bootcamp/core/services/auth/auth_service.dart';
import 'package:akademi_bootcamp/product/detail_page/detail_page.dart';
import 'package:akademi_bootcamp/product/profile/profile_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/components/app_bar/custom_app_bar.dart';
import '../../core/components/cards/group_item_card.dart';
import '../../core/components/image/profile_photo_widget.dart';
import '../../core/constants/image/image_constants.dart';
import '../../core/constants/theme/theme_constants.dart';
import '../../core/model/group_model.dart';
import '../../core/services/firestore/events_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends BaseState<ProfileView> {
  ProfileViewModel _viewModel = ProfileViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AuthService.instance.uid != null
            ? CustomAppBar(
                context: context,
                center: AppBarWidgets.LOGO,
                right: AppBarWidgets.EDIT,
                onTapRight: () => NavigationService.instance.navigateToPage(path: NavigationConstants.PROFILE_EDIT),
              )
            : null,
        body: AuthService.instance.uid != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                userHeader(),
                label(),
                events(),
              ])
            : SizedBox(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Profil oluşturabilmek için"),
                      InkWell(
                          onTap: () {
                            NavigationService.instance.navigateToPage(path: NavigationConstants.AUTH);
                          },
                          child: Text("Kayıt Ol veya Giriş Yap")),
                    ],
                  ),
                ),
              ));
  }

  Expanded events() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
          stream: EventsService.instance.fetchUserGroups(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<GroupModel> groupList = snapshot.data!.docs.map((doc) => GroupModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
              return Container(
                width: deviceWidth,
                height: deviceHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          itemCount: groupList.isNotEmpty ? groupList.length : 0,
                          itemBuilder: (context, index) {
                            return slidableItem(groupList[index], context);
                          }),
                    ),
                  ],
                ),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(height: deviceHeight, child: Center(child: CircularProgressIndicator()));
            } else {
              return SizedBox(height: deviceHeight, child: Center(child: Text("Henüz bir etkinliği favoriye almadın..")));
            }
          }),
    );
  }

  Slidable slidableItem(GroupModel groupModel, BuildContext context) {
    return Slidable(
        startActionPane: groupPane(groupModel),
        endActionPane: eventPane(groupModel),
        child: GroupItemCard(
            group: groupModel,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  if (groupModel.event != null) {
                    return DetailPage(eventModel: groupModel.event!);
                  }
                  return SizedBox();
                },
              ));
            }));
  }

  ActionPane eventPane(GroupModel groupModel) {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          padding: EdgeInsets.zero,
          onPressed: (context) {
            if (groupModel.event != null) {
              _viewModel.removeFav(groupModel.event!);
              setState(() {});
            }
          },
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          icon: Icons.delete,
          label: 'Favorilerden Kaldır',
        ),
      ],
    );
  }

  ActionPane groupPane(GroupModel groupModel) {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
            padding: EdgeInsets.zero,
            onPressed: (context) {
              if (_viewModel.containsUser(groupModel)) {
                _viewModel.leaveGroup(context, groupModel.event);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      backgroundColor: AppColors.orange,
                      action: SnackBarAction(
                        label: "Geri al",
                        onPressed: () {
                          _viewModel.joinGroup(context, groupModel.event);
                        },
                      ),
                      content: Text("Gruptan ayrıldınız.")),
                );
              } else {
                _viewModel.joinGroup(context, groupModel.event);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: AppColors.green, content: Text("Gruba katıldınız.")),
                );
              }
            },
            backgroundColor: _viewModel.containsUser(groupModel) ? AppColors.grey : AppColors.green,
            foregroundColor: Colors.white,
            icon: _viewModel.containsUser(groupModel) ? Icons.exit_to_app_rounded : Icons.add,
            label: _viewModel.containsUser(groupModel) ? 'Gruptan Ayrıl' : 'Gruba Katıl')
      ],
    );
  }

  Padding label() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.mediumSize,
      ),
      child: Text("Favorilerim", style: themeData.textTheme.headlineSmall),
    );
  }

  Widget userHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          ProfilePhotoWidget(radius: 50, photoUrl: AuthService.instance.currentUser?.photoUrl),
          SizedBox(
            width: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_viewModel.currentUser?.fullname ?? ''),
              Row(children: [Image.asset(ImageConstants.LOCATION), Text("İstanbul")]),
              CircularProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(AppColors.vanillaShake), value: 0.2)
            ],
          )
        ],
      ),
    );
  }
}
