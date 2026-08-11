import 'division_model.dart';
import 'district_model.dart';
import 'upazila_model.dart';


enum HouseType { flat, room, seat, unit }

extension HouseTypeLabel on HouseType {
  String get bnLabel {
    switch (this) {
      case HouseType.flat:
        return 'Flat';
      case HouseType.room:
        return 'Room';
      case HouseType.seat:
        return 'Seat';
      case HouseType.unit:
        return 'Unit';
    }
  }
}


class SearchFilterModel {
  const SearchFilterModel({
    required this.month,
    required this.houseType,
    required this.division,
    required this.district,
    required this.upazila,
    required this.roomOrSeat,
  });

  final String month;
  final HouseType houseType;
  final DivisionModel division;
  final DistrictModel district;
  final UpazilaModel upazila;
  final String roomOrSeat;

  Map<String, dynamic> toQueryParams() {
    return {
      'month': month,
      'house_type': houseType.name,
      'division_id': division.id,
      'district_id': district.id,
      'upazila_id': upazila.id,
      'room_or_seat': roomOrSeat,
    };
  }
}