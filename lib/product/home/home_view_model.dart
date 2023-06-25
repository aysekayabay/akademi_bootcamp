import 'package:akademi_bootcamp/core/model/event_model.dart';
import 'package:akademi_bootcamp/core/services/api/etkinlikIO_service.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../detail_page/detail_page.dart';
part 'home_view_model.g.dart';

class HomeViewModel = _HomeViewModelBase with _$HomeViewModel;

abstract class _HomeViewModelBase with Store {
  ScrollController scrollController = ScrollController();
  FocusNode focusNode = FocusNode();
  @observable
  bool isLoading = true;
  @observable
  List<EventModel>? eventList = [];

  @observable
  bool seeAllIsActive = false;

  @action
  seeAll() {
    seeAllIsActive = !seeAllIsActive;
  }

  @observable
  List<Format>? categoryList = [];

  @action
  init() async {
    await getEventList();
  }

  Future<void> getEventList() async {
    eventList = await EtkinlikIOService.instance.fetchEventList();
    categoryList = EtkinlikIOService.instance.categoryList;
    if (categoryList != null && categoryList!.length > 0) {
      filterEventsByCategory(categoryList!.first);
    }
    isLoading = false;
  }

  @observable
  List<EventModel>? filteredEventList;
  @action
  void filterEventsByCategory(Format selectedCategory) {
    filteredEventList = eventList?.where((event) => event.format?.id == selectedCategory.id).toList();
  }

  @observable
  int selectedIndex = 0;

  @action
  bool isSelected(int index) => selectedIndex == index;

  @action
  void selectCategory(int index) {
    selectedIndex = index;
    filterEventsByCategory(categoryList![selectedIndex]);
  }

  @action
  void tapped(int index) {
    if (!isSelected(index)) {
      selectCategory(index);
      if (!seeAllIsActive) {
        scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.ease);
      }
    }
  }

  void navigateToDetailPage(BuildContext context, EventModel eventModel) {
    focusNode.unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return DetailPage(eventModel: eventModel);
      },
    ));
  }
}
