// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QualificationsTable extends Qualifications
    with TableInfo<$QualificationsTable, Qualification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QualificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qualifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Qualification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Qualification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Qualification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QualificationsTable createAlias(String alias) {
    return $QualificationsTable(attachedDatabase, alias);
  }
}

class Qualification extends DataClass implements Insertable<Qualification> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String name;
  final int sortOrder;
  const Qualification({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QualificationsCompanion toCompanion(bool nullToAbsent) {
    return QualificationsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory Qualification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Qualification(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Qualification copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? name,
    int? sortOrder,
  }) => Qualification(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Qualification copyWithCompanion(QualificationsCompanion data) {
    return Qualification(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Qualification(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deleted, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Qualification &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class QualificationsCompanion extends UpdateCompanion<Qualification> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QualificationsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QualificationsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Qualification> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QualificationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QualificationsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QualificationsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _personnelNoMeta = const VerificationMeta(
    'personnelNo',
  );
  @override
  late final GeneratedColumn<String> personnelNo = GeneratedColumn<String>(
    'personnel_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _youthMeta = const VerificationMeta('youth');
  @override
  late final GeneratedColumn<bool> youth = GeneratedColumn<bool>(
    'youth',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("youth" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    lastName,
    firstName,
    personnelNo,
    youth,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('personnel_no')) {
      context.handle(
        _personnelNoMeta,
        personnelNo.isAcceptableOrUnknown(
          data['personnel_no']!,
          _personnelNoMeta,
        ),
      );
    }
    if (data.containsKey('youth')) {
      context.handle(
        _youthMeta,
        youth.isAcceptableOrUnknown(data['youth']!, _youthMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      personnelNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personnel_no'],
      ),
      youth: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}youth'],
      )!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String lastName;
  final String firstName;
  final String? personnelNo;
  final bool youth;
  const Person({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.lastName,
    required this.firstName,
    this.personnelNo,
    required this.youth,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['last_name'] = Variable<String>(lastName);
    map['first_name'] = Variable<String>(firstName);
    if (!nullToAbsent || personnelNo != null) {
      map['personnel_no'] = Variable<String>(personnelNo);
    }
    map['youth'] = Variable<bool>(youth);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      lastName: Value(lastName),
      firstName: Value(firstName),
      personnelNo: personnelNo == null && nullToAbsent
          ? const Value.absent()
          : Value(personnelNo),
      youth: Value(youth),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      lastName: serializer.fromJson<String>(json['lastName']),
      firstName: serializer.fromJson<String>(json['firstName']),
      personnelNo: serializer.fromJson<String?>(json['personnelNo']),
      youth: serializer.fromJson<bool>(json['youth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'lastName': serializer.toJson<String>(lastName),
      'firstName': serializer.toJson<String>(firstName),
      'personnelNo': serializer.toJson<String?>(personnelNo),
      'youth': serializer.toJson<bool>(youth),
    };
  }

  Person copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? lastName,
    String? firstName,
    Value<String?> personnelNo = const Value.absent(),
    bool? youth,
  }) => Person(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    lastName: lastName ?? this.lastName,
    firstName: firstName ?? this.firstName,
    personnelNo: personnelNo.present ? personnelNo.value : this.personnelNo,
    youth: youth ?? this.youth,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      personnelNo: data.personnelNo.present
          ? data.personnelNo.value
          : this.personnelNo,
      youth: data.youth.present ? data.youth.value : this.youth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('personnelNo: $personnelNo, ')
          ..write('youth: $youth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    lastName,
    firstName,
    personnelNo,
    youth,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.lastName == this.lastName &&
          other.firstName == this.firstName &&
          other.personnelNo == this.personnelNo &&
          other.youth == this.youth);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> lastName;
  final Value<String> firstName;
  final Value<String?> personnelNo;
  final Value<bool> youth;
  final Value<int> rowid;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.personnelNo = const Value.absent(),
    this.youth = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String lastName,
    this.firstName = const Value.absent(),
    this.personnelNo = const Value.absent(),
    this.youth = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lastName = Value(lastName);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? lastName,
    Expression<String>? firstName,
    Expression<String>? personnelNo,
    Expression<bool>? youth,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (lastName != null) 'last_name': lastName,
      if (firstName != null) 'first_name': firstName,
      if (personnelNo != null) 'personnel_no': personnelNo,
      if (youth != null) 'youth': youth,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? lastName,
    Value<String>? firstName,
    Value<String?>? personnelNo,
    Value<bool>? youth,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      personnelNo: personnelNo ?? this.personnelNo,
      youth: youth ?? this.youth,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (personnelNo.present) {
      map['personnel_no'] = Variable<String>(personnelNo.value);
    }
    if (youth.present) {
      map['youth'] = Variable<bool>(youth.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('personnelNo: $personnelNo, ')
          ..write('youth: $youth, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonQualificationsTable extends PersonQualifications
    with TableInfo<$PersonQualificationsTable, PersonQualification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonQualificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualificationIdMeta = const VerificationMeta(
    'qualificationId',
  );
  @override
  late final GeneratedColumn<String> qualificationId = GeneratedColumn<String>(
    'qualification_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    personId,
    qualificationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_qualifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonQualification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('qualification_id')) {
      context.handle(
        _qualificationIdMeta,
        qualificationId.isAcceptableOrUnknown(
          data['qualification_id']!,
          _qualificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualificationIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonQualification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonQualification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      qualificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qualification_id'],
      )!,
    );
  }

  @override
  $PersonQualificationsTable createAlias(String alias) {
    return $PersonQualificationsTable(attachedDatabase, alias);
  }
}

class PersonQualification extends DataClass
    implements Insertable<PersonQualification> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String personId;
  final String qualificationId;
  const PersonQualification({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.personId,
    required this.qualificationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['person_id'] = Variable<String>(personId);
    map['qualification_id'] = Variable<String>(qualificationId);
    return map;
  }

  PersonQualificationsCompanion toCompanion(bool nullToAbsent) {
    return PersonQualificationsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      personId: Value(personId),
      qualificationId: Value(qualificationId),
    );
  }

  factory PersonQualification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonQualification(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      personId: serializer.fromJson<String>(json['personId']),
      qualificationId: serializer.fromJson<String>(json['qualificationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'personId': serializer.toJson<String>(personId),
      'qualificationId': serializer.toJson<String>(qualificationId),
    };
  }

  PersonQualification copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? personId,
    String? qualificationId,
  }) => PersonQualification(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    personId: personId ?? this.personId,
    qualificationId: qualificationId ?? this.qualificationId,
  );
  PersonQualification copyWithCompanion(PersonQualificationsCompanion data) {
    return PersonQualification(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      personId: data.personId.present ? data.personId.value : this.personId,
      qualificationId: data.qualificationId.present
          ? data.qualificationId.value
          : this.qualificationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonQualification(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('personId: $personId, ')
          ..write('qualificationId: $qualificationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deleted, personId, qualificationId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonQualification &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.personId == this.personId &&
          other.qualificationId == this.qualificationId);
}

class PersonQualificationsCompanion
    extends UpdateCompanion<PersonQualification> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> personId;
  final Value<String> qualificationId;
  final Value<int> rowid;
  const PersonQualificationsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.personId = const Value.absent(),
    this.qualificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonQualificationsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String personId,
    required String qualificationId,
    this.rowid = const Value.absent(),
  }) : personId = Value(personId),
       qualificationId = Value(qualificationId);
  static Insertable<PersonQualification> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? personId,
    Expression<String>? qualificationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (personId != null) 'person_id': personId,
      if (qualificationId != null) 'qualification_id': qualificationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonQualificationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? personId,
    Value<String>? qualificationId,
    Value<int>? rowid,
  }) {
    return PersonQualificationsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      personId: personId ?? this.personId,
      qualificationId: qualificationId ?? this.qualificationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (qualificationId.present) {
      map['qualification_id'] = Variable<String>(qualificationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonQualificationsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('personId: $personId, ')
          ..write('qualificationId: $qualificationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fahrzeug'),
  );
  static const VerificationMeta _callSignMeta = const VerificationMeta(
    'callSign',
  );
  @override
  late final GeneratedColumn<String> callSign = GeneratedColumn<String>(
    'call_sign',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('einsatzbereit'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    name,
    type,
    kind,
    callSign,
    status,
    externalId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('call_sign')) {
      context.handle(
        _callSignMeta,
        callSign.isAcceptableOrUnknown(data['call_sign']!, _callSignMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      callSign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}call_sign'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String name;
  final String? type;

  /// `fahrzeug`, `boot` oder `anhaenger`.
  final String kind;
  final String? callSign;

  /// `einsatzbereit`, `bedingt_einsatzbereit`, `ausser_dienst`, `werkstatt`.
  final String status;

  /// ID des Fahrzeugs in Materialkompass (später).
  final String? externalId;
  final int sortOrder;
  const Vehicle({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.name,
    this.type,
    required this.kind,
    this.callSign,
    required this.status,
    this.externalId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || callSign != null) {
      map['call_sign'] = Variable<String>(callSign);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      name: Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      kind: Value(kind),
      callSign: callSign == null && nullToAbsent
          ? const Value.absent()
          : Value(callSign),
      status: Value(status),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      sortOrder: Value(sortOrder),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      kind: serializer.fromJson<String>(json['kind']),
      callSign: serializer.fromJson<String?>(json['callSign']),
      status: serializer.fromJson<String>(json['status']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String?>(type),
      'kind': serializer.toJson<String>(kind),
      'callSign': serializer.toJson<String?>(callSign),
      'status': serializer.toJson<String>(status),
      'externalId': serializer.toJson<String?>(externalId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Vehicle copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? name,
    Value<String?> type = const Value.absent(),
    String? kind,
    Value<String?> callSign = const Value.absent(),
    String? status,
    Value<String?> externalId = const Value.absent(),
    int? sortOrder,
  }) => Vehicle(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    type: type.present ? type.value : this.type,
    kind: kind ?? this.kind,
    callSign: callSign.present ? callSign.value : this.callSign,
    status: status ?? this.status,
    externalId: externalId.present ? externalId.value : this.externalId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      kind: data.kind.present ? data.kind.value : this.kind,
      callSign: data.callSign.present ? data.callSign.value : this.callSign,
      status: data.status.present ? data.status.value : this.status,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('kind: $kind, ')
          ..write('callSign: $callSign, ')
          ..write('status: $status, ')
          ..write('externalId: $externalId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    name,
    type,
    kind,
    callSign,
    status,
    externalId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.type == this.type &&
          other.kind == this.kind &&
          other.callSign == this.callSign &&
          other.status == this.status &&
          other.externalId == this.externalId &&
          other.sortOrder == this.sortOrder);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String?> type;
  final Value<String> kind;
  final Value<String?> callSign;
  final Value<String> status;
  final Value<String?> externalId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.kind = const Value.absent(),
    this.callSign = const Value.absent(),
    this.status = const Value.absent(),
    this.externalId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.type = const Value.absent(),
    this.kind = const Value.absent(),
    this.callSign = const Value.absent(),
    this.status = const Value.absent(),
    this.externalId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Vehicle> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? kind,
    Expression<String>? callSign,
    Expression<String>? status,
    Expression<String>? externalId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (kind != null) 'kind': kind,
      if (callSign != null) 'call_sign': callSign,
      if (status != null) 'status': status,
      if (externalId != null) 'external_id': externalId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String?>? type,
    Value<String>? kind,
    Value<String?>? callSign,
    Value<String>? status,
    Value<String?>? externalId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      type: type ?? this.type,
      kind: kind ?? this.kind,
      callSign: callSign ?? this.callSign,
      status: status ?? this.status,
      externalId: externalId ?? this.externalId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (callSign.present) {
      map['call_sign'] = Variable<String>(callSign.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('kind: $kind, ')
          ..write('callSign: $callSign, ')
          ..write('status: $status, ')
          ..write('externalId: $externalId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CrewFunctionsTable extends CrewFunctions
    with TableInfo<$CrewFunctionsTable, CrewFunction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrewFunctionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredQualificationIdMeta =
      const VerificationMeta('requiredQualificationId');
  @override
  late final GeneratedColumn<String> requiredQualificationId =
      GeneratedColumn<String>(
        'required_qualification_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    vehicleId,
    name,
    requiredQualificationId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crew_functions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CrewFunction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('required_qualification_id')) {
      context.handle(
        _requiredQualificationIdMeta,
        requiredQualificationId.isAcceptableOrUnknown(
          data['required_qualification_id']!,
          _requiredQualificationIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrewFunction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrewFunction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      requiredQualificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_qualification_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CrewFunctionsTable createAlias(String alias) {
    return $CrewFunctionsTable(attachedDatabase, alias);
  }
}

class CrewFunction extends DataClass implements Insertable<CrewFunction> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String? vehicleId;
  final String name;
  final String? requiredQualificationId;
  final int sortOrder;
  const CrewFunction({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    this.vehicleId,
    required this.name,
    this.requiredQualificationId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || vehicleId != null) {
      map['vehicle_id'] = Variable<String>(vehicleId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || requiredQualificationId != null) {
      map['required_qualification_id'] = Variable<String>(
        requiredQualificationId,
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CrewFunctionsCompanion toCompanion(bool nullToAbsent) {
    return CrewFunctionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      vehicleId: vehicleId == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleId),
      name: Value(name),
      requiredQualificationId: requiredQualificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredQualificationId),
      sortOrder: Value(sortOrder),
    );
  }

  factory CrewFunction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrewFunction(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      vehicleId: serializer.fromJson<String?>(json['vehicleId']),
      name: serializer.fromJson<String>(json['name']),
      requiredQualificationId: serializer.fromJson<String?>(
        json['requiredQualificationId'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'vehicleId': serializer.toJson<String?>(vehicleId),
      'name': serializer.toJson<String>(name),
      'requiredQualificationId': serializer.toJson<String?>(
        requiredQualificationId,
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CrewFunction copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    Value<String?> vehicleId = const Value.absent(),
    String? name,
    Value<String?> requiredQualificationId = const Value.absent(),
    int? sortOrder,
  }) => CrewFunction(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    vehicleId: vehicleId.present ? vehicleId.value : this.vehicleId,
    name: name ?? this.name,
    requiredQualificationId: requiredQualificationId.present
        ? requiredQualificationId.value
        : this.requiredQualificationId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CrewFunction copyWithCompanion(CrewFunctionsCompanion data) {
    return CrewFunction(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      name: data.name.present ? data.name.value : this.name,
      requiredQualificationId: data.requiredQualificationId.present
          ? data.requiredQualificationId.value
          : this.requiredQualificationId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrewFunction(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('requiredQualificationId: $requiredQualificationId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    vehicleId,
    name,
    requiredQualificationId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrewFunction &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.vehicleId == this.vehicleId &&
          other.name == this.name &&
          other.requiredQualificationId == this.requiredQualificationId &&
          other.sortOrder == this.sortOrder);
}

class CrewFunctionsCompanion extends UpdateCompanion<CrewFunction> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String?> vehicleId;
  final Value<String> name;
  final Value<String?> requiredQualificationId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CrewFunctionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.name = const Value.absent(),
    this.requiredQualificationId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CrewFunctionsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.vehicleId = const Value.absent(),
    required String name,
    this.requiredQualificationId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CrewFunction> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? vehicleId,
    Expression<String>? name,
    Expression<String>? requiredQualificationId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (name != null) 'name': name,
      if (requiredQualificationId != null)
        'required_qualification_id': requiredQualificationId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CrewFunctionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String?>? vehicleId,
    Value<String>? name,
    Value<String?>? requiredQualificationId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CrewFunctionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      requiredQualificationId:
          requiredQualificationId ?? this.requiredQualificationId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (requiredQualificationId.present) {
      map['required_qualification_id'] = Variable<String>(
        requiredQualificationId.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrewFunctionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('requiredQualificationId: $requiredQualificationId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CrewPatternsTable extends CrewPatterns
    with TableInfo<$CrewPatternsTable, CrewPattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrewPatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    vehicleId,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crew_patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<CrewPattern> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrewPattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrewPattern(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CrewPatternsTable createAlias(String alias) {
    return $CrewPatternsTable(attachedDatabase, alias);
  }
}

class CrewPattern extends DataClass implements Insertable<CrewPattern> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String vehicleId;
  final String name;
  final int sortOrder;
  const CrewPattern({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.vehicleId,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CrewPatternsCompanion toCompanion(bool nullToAbsent) {
    return CrewPatternsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      vehicleId: Value(vehicleId),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory CrewPattern.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrewPattern(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CrewPattern copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? vehicleId,
    String? name,
    int? sortOrder,
  }) => CrewPattern(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    vehicleId: vehicleId ?? this.vehicleId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CrewPattern copyWithCompanion(CrewPatternsCompanion data) {
    return CrewPattern(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrewPattern(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deleted, vehicleId, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrewPattern &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.vehicleId == this.vehicleId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class CrewPatternsCompanion extends UpdateCompanion<CrewPattern> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> vehicleId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CrewPatternsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CrewPatternsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String vehicleId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       name = Value(name);
  static Insertable<CrewPattern> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? vehicleId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CrewPatternsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? vehicleId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CrewPatternsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrewPatternsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CrewPatternFunctionsTable extends CrewPatternFunctions
    with TableInfo<$CrewPatternFunctionsTable, CrewPatternFunction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrewPatternFunctionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<String> patternId = GeneratedColumn<String>(
    'pattern_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _functionIdMeta = const VerificationMeta(
    'functionId',
  );
  @override
  late final GeneratedColumn<String> functionId = GeneratedColumn<String>(
    'function_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    patternId,
    functionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crew_pattern_functions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CrewPatternFunction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patternIdMeta);
    }
    if (data.containsKey('function_id')) {
      context.handle(
        _functionIdMeta,
        functionId.isAcceptableOrUnknown(data['function_id']!, _functionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_functionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrewPatternFunction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrewPatternFunction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_id'],
      )!,
      functionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}function_id'],
      )!,
    );
  }

  @override
  $CrewPatternFunctionsTable createAlias(String alias) {
    return $CrewPatternFunctionsTable(attachedDatabase, alias);
  }
}

class CrewPatternFunction extends DataClass
    implements Insertable<CrewPatternFunction> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String patternId;
  final String functionId;
  const CrewPatternFunction({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.patternId,
    required this.functionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['pattern_id'] = Variable<String>(patternId);
    map['function_id'] = Variable<String>(functionId);
    return map;
  }

  CrewPatternFunctionsCompanion toCompanion(bool nullToAbsent) {
    return CrewPatternFunctionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      patternId: Value(patternId),
      functionId: Value(functionId),
    );
  }

  factory CrewPatternFunction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrewPatternFunction(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      patternId: serializer.fromJson<String>(json['patternId']),
      functionId: serializer.fromJson<String>(json['functionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'patternId': serializer.toJson<String>(patternId),
      'functionId': serializer.toJson<String>(functionId),
    };
  }

  CrewPatternFunction copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? patternId,
    String? functionId,
  }) => CrewPatternFunction(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    patternId: patternId ?? this.patternId,
    functionId: functionId ?? this.functionId,
  );
  CrewPatternFunction copyWithCompanion(CrewPatternFunctionsCompanion data) {
    return CrewPatternFunction(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      functionId: data.functionId.present
          ? data.functionId.value
          : this.functionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrewPatternFunction(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('patternId: $patternId, ')
          ..write('functionId: $functionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deleted, patternId, functionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrewPatternFunction &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.patternId == this.patternId &&
          other.functionId == this.functionId);
}

class CrewPatternFunctionsCompanion
    extends UpdateCompanion<CrewPatternFunction> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> patternId;
  final Value<String> functionId;
  final Value<int> rowid;
  const CrewPatternFunctionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.patternId = const Value.absent(),
    this.functionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CrewPatternFunctionsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String patternId,
    required String functionId,
    this.rowid = const Value.absent(),
  }) : patternId = Value(patternId),
       functionId = Value(functionId);
  static Insertable<CrewPatternFunction> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? patternId,
    Expression<String>? functionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (patternId != null) 'pattern_id': patternId,
      if (functionId != null) 'function_id': functionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CrewPatternFunctionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? patternId,
    Value<String>? functionId,
    Value<int>? rowid,
  }) {
    return CrewPatternFunctionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      patternId: patternId ?? this.patternId,
      functionId: functionId ?? this.functionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<String>(patternId.value);
    }
    if (functionId.present) {
      map['function_id'] = Variable<String>(functionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrewPatternFunctionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('patternId: $patternId, ')
          ..write('functionId: $functionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeywordsTable extends Keywords with TableInfo<$KeywordsTable, Keyword> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeywordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourcesMeta = const VerificationMeta(
    'resources',
  );
  @override
  late final GeneratedColumn<String> resources = GeneratedColumn<String>(
    'resources',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialRightsMeta = const VerificationMeta(
    'specialRights',
  );
  @override
  late final GeneratedColumn<bool> specialRights = GeneratedColumn<bool>(
    'special_rights',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("special_rights" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    code,
    category,
    description,
    resources,
    specialRights,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keywords';
  @override
  VerificationContext validateIntegrity(
    Insertable<Keyword> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('resources')) {
      context.handle(
        _resourcesMeta,
        resources.isAcceptableOrUnknown(data['resources']!, _resourcesMeta),
      );
    }
    if (data.containsKey('special_rights')) {
      context.handle(
        _specialRightsMeta,
        specialRights.isAcceptableOrUnknown(
          data['special_rights']!,
          _specialRightsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Keyword map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Keyword(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      resources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resources'],
      ),
      specialRights: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}special_rights'],
      )!,
    );
  }

  @override
  $KeywordsTable createAlias(String alias) {
    return $KeywordsTable(attachedDatabase, alias);
  }
}

class Keyword extends DataClass implements Insertable<Keyword> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String code;
  final String? category;
  final String? description;

  /// Einsatzmittel laut Alarm- und Ausrückeordnung (AAO), Freitext.
  final String? resources;
  final bool specialRights;
  const Keyword({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.code,
    this.category,
    this.description,
    this.resources,
    required this.specialRights,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || resources != null) {
      map['resources'] = Variable<String>(resources);
    }
    map['special_rights'] = Variable<bool>(specialRights);
    return map;
  }

  KeywordsCompanion toCompanion(bool nullToAbsent) {
    return KeywordsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      code: Value(code),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      resources: resources == null && nullToAbsent
          ? const Value.absent()
          : Value(resources),
      specialRights: Value(specialRights),
    );
  }

  factory Keyword.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Keyword(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      code: serializer.fromJson<String>(json['code']),
      category: serializer.fromJson<String?>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      resources: serializer.fromJson<String?>(json['resources']),
      specialRights: serializer.fromJson<bool>(json['specialRights']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'code': serializer.toJson<String>(code),
      'category': serializer.toJson<String?>(category),
      'description': serializer.toJson<String?>(description),
      'resources': serializer.toJson<String?>(resources),
      'specialRights': serializer.toJson<bool>(specialRights),
    };
  }

  Keyword copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? code,
    Value<String?> category = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> resources = const Value.absent(),
    bool? specialRights,
  }) => Keyword(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    code: code ?? this.code,
    category: category.present ? category.value : this.category,
    description: description.present ? description.value : this.description,
    resources: resources.present ? resources.value : this.resources,
    specialRights: specialRights ?? this.specialRights,
  );
  Keyword copyWithCompanion(KeywordsCompanion data) {
    return Keyword(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      code: data.code.present ? data.code.value : this.code,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      resources: data.resources.present ? data.resources.value : this.resources,
      specialRights: data.specialRights.present
          ? data.specialRights.value
          : this.specialRights,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Keyword(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('code: $code, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('resources: $resources, ')
          ..write('specialRights: $specialRights')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    code,
    category,
    description,
    resources,
    specialRights,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Keyword &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.code == this.code &&
          other.category == this.category &&
          other.description == this.description &&
          other.resources == this.resources &&
          other.specialRights == this.specialRights);
}

class KeywordsCompanion extends UpdateCompanion<Keyword> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> code;
  final Value<String?> category;
  final Value<String?> description;
  final Value<String?> resources;
  final Value<bool> specialRights;
  final Value<int> rowid;
  const KeywordsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.code = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.resources = const Value.absent(),
    this.specialRights = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeywordsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String code,
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.resources = const Value.absent(),
    this.specialRights = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code);
  static Insertable<Keyword> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? code,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? resources,
    Expression<bool>? specialRights,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (code != null) 'code': code,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (resources != null) 'resources': resources,
      if (specialRights != null) 'special_rights': specialRights,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeywordsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? code,
    Value<String?>? category,
    Value<String?>? description,
    Value<String?>? resources,
    Value<bool>? specialRights,
    Value<int>? rowid,
  }) {
    return KeywordsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      code: code ?? this.code,
      category: category ?? this.category,
      description: description ?? this.description,
      resources: resources ?? this.resources,
      specialRights: specialRights ?? this.specialRights,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (resources.present) {
      map['resources'] = Variable<String>(resources.value);
    }
    if (specialRights.present) {
      map['special_rights'] = Variable<bool>(specialRights.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeywordsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('code: $code, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('resources: $resources, ')
          ..write('specialRights: $specialRights, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(19 * 60),
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keywordIdMeta = const VerificationMeta(
    'keywordId',
  );
  @override
  late final GeneratedColumn<String> keywordId = GeneratedColumn<String>(
    'keyword_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalsMeta = const VerificationMeta('goals');
  @override
  late final GeneratedColumn<String> goals = GeneratedColumn<String>(
    'goals',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _scenarioMeta = const VerificationMeta(
    'scenario',
  );
  @override
  late final GeneratedColumn<String> scenario = GeneratedColumn<String>(
    'scenario',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('entwurf'),
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeModeMeta = const VerificationMeta(
    'timeMode',
  );
  @override
  late final GeneratedColumn<String> timeMode = GeneratedColumn<String>(
    'time_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('uhrzeit'),
  );
  static const VerificationMeta _alarmAddressMeta = const VerificationMeta(
    'alarmAddress',
  );
  @override
  late final GeneratedColumn<String> alarmAddress = GeneratedColumn<String>(
    'alarm_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmReporterMeta = const VerificationMeta(
    'alarmReporter',
  );
  @override
  late final GeneratedColumn<String> alarmReporter = GeneratedColumn<String>(
    'alarm_reporter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmSpecialRightsMeta =
      const VerificationMeta('alarmSpecialRights');
  @override
  late final GeneratedColumn<bool> alarmSpecialRights = GeneratedColumn<bool>(
    'alarm_special_rights',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm_special_rights" IN (0, 1))',
    ),
  );
  static const VerificationMeta _alarmVehiclesMeta = const VerificationMeta(
    'alarmVehicles',
  );
  @override
  late final GeneratedColumn<String> alarmVehicles = GeneratedColumn<String>(
    'alarm_vehicles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    title,
    date,
    startMinutes,
    endMinutes,
    location,
    unit,
    topic,
    keywordId,
    goals,
    scenario,
    status,
    approvedBy,
    approvedAt,
    timeMode,
    alarmAddress,
    alarmReporter,
    alarmSpecialRights,
    alarmVehicles,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('keyword_id')) {
      context.handle(
        _keywordIdMeta,
        keywordId.isAcceptableOrUnknown(data['keyword_id']!, _keywordIdMeta),
      );
    }
    if (data.containsKey('goals')) {
      context.handle(
        _goalsMeta,
        goals.isAcceptableOrUnknown(data['goals']!, _goalsMeta),
      );
    }
    if (data.containsKey('scenario')) {
      context.handle(
        _scenarioMeta,
        scenario.isAcceptableOrUnknown(data['scenario']!, _scenarioMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('time_mode')) {
      context.handle(
        _timeModeMeta,
        timeMode.isAcceptableOrUnknown(data['time_mode']!, _timeModeMeta),
      );
    }
    if (data.containsKey('alarm_address')) {
      context.handle(
        _alarmAddressMeta,
        alarmAddress.isAcceptableOrUnknown(
          data['alarm_address']!,
          _alarmAddressMeta,
        ),
      );
    }
    if (data.containsKey('alarm_reporter')) {
      context.handle(
        _alarmReporterMeta,
        alarmReporter.isAcceptableOrUnknown(
          data['alarm_reporter']!,
          _alarmReporterMeta,
        ),
      );
    }
    if (data.containsKey('alarm_special_rights')) {
      context.handle(
        _alarmSpecialRightsMeta,
        alarmSpecialRights.isAcceptableOrUnknown(
          data['alarm_special_rights']!,
          _alarmSpecialRightsMeta,
        ),
      );
    }
    if (data.containsKey('alarm_vehicles')) {
      context.handle(
        _alarmVehiclesMeta,
        alarmVehicles.isAcceptableOrUnknown(
          data['alarm_vehicles']!,
          _alarmVehiclesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      keywordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword_id'],
      ),
      goals: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goals'],
      )!,
      scenario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scenario'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      timeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_mode'],
      )!,
      alarmAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_address'],
      ),
      alarmReporter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_reporter'],
      ),
      alarmSpecialRights: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm_special_rights'],
      ),
      alarmVehicles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_vehicles'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String title;
  final DateTime date;

  /// Beginn und Ende in Minuten nach Mitternacht (19:00 = 1140).
  final int startMinutes;
  final int? endMinutes;
  final String? location;
  final String? unit;
  final String? topic;
  final String? keywordId;

  /// Lernziele als JSON-Liste von Texten.
  final String goals;
  final String? scenario;

  /// `entwurf`, `zur_freigabe`, `freigegeben`
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;

  /// Anzeige der Zeiten im Alarmierungsplan: `uhrzeit` oder `relativ`.
  final String timeMode;
  final String? alarmAddress;
  final String? alarmReporter;

  /// `null` = Vorgabe aus dem Alarmstichwort übernehmen.
  final bool? alarmSpecialRights;

  /// `null` = aus dem Alarmierungsplan (Erstalarm) übernehmen.
  final String? alarmVehicles;
  const Exercise({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.title,
    required this.date,
    required this.startMinutes,
    this.endMinutes,
    this.location,
    this.unit,
    this.topic,
    this.keywordId,
    required this.goals,
    this.scenario,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.timeMode,
    this.alarmAddress,
    this.alarmReporter,
    this.alarmSpecialRights,
    this.alarmVehicles,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['start_minutes'] = Variable<int>(startMinutes);
    if (!nullToAbsent || endMinutes != null) {
      map['end_minutes'] = Variable<int>(endMinutes);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || keywordId != null) {
      map['keyword_id'] = Variable<String>(keywordId);
    }
    map['goals'] = Variable<String>(goals);
    if (!nullToAbsent || scenario != null) {
      map['scenario'] = Variable<String>(scenario);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    map['time_mode'] = Variable<String>(timeMode);
    if (!nullToAbsent || alarmAddress != null) {
      map['alarm_address'] = Variable<String>(alarmAddress);
    }
    if (!nullToAbsent || alarmReporter != null) {
      map['alarm_reporter'] = Variable<String>(alarmReporter);
    }
    if (!nullToAbsent || alarmSpecialRights != null) {
      map['alarm_special_rights'] = Variable<bool>(alarmSpecialRights);
    }
    if (!nullToAbsent || alarmVehicles != null) {
      map['alarm_vehicles'] = Variable<String>(alarmVehicles);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      title: Value(title),
      date: Value(date),
      startMinutes: Value(startMinutes),
      endMinutes: endMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinutes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      keywordId: keywordId == null && nullToAbsent
          ? const Value.absent()
          : Value(keywordId),
      goals: Value(goals),
      scenario: scenario == null && nullToAbsent
          ? const Value.absent()
          : Value(scenario),
      status: Value(status),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      timeMode: Value(timeMode),
      alarmAddress: alarmAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmAddress),
      alarmReporter: alarmReporter == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmReporter),
      alarmSpecialRights: alarmSpecialRights == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmSpecialRights),
      alarmVehicles: alarmVehicles == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmVehicles),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int?>(json['endMinutes']),
      location: serializer.fromJson<String?>(json['location']),
      unit: serializer.fromJson<String?>(json['unit']),
      topic: serializer.fromJson<String?>(json['topic']),
      keywordId: serializer.fromJson<String?>(json['keywordId']),
      goals: serializer.fromJson<String>(json['goals']),
      scenario: serializer.fromJson<String?>(json['scenario']),
      status: serializer.fromJson<String>(json['status']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      timeMode: serializer.fromJson<String>(json['timeMode']),
      alarmAddress: serializer.fromJson<String?>(json['alarmAddress']),
      alarmReporter: serializer.fromJson<String?>(json['alarmReporter']),
      alarmSpecialRights: serializer.fromJson<bool?>(
        json['alarmSpecialRights'],
      ),
      alarmVehicles: serializer.fromJson<String?>(json['alarmVehicles']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int?>(endMinutes),
      'location': serializer.toJson<String?>(location),
      'unit': serializer.toJson<String?>(unit),
      'topic': serializer.toJson<String?>(topic),
      'keywordId': serializer.toJson<String?>(keywordId),
      'goals': serializer.toJson<String>(goals),
      'scenario': serializer.toJson<String?>(scenario),
      'status': serializer.toJson<String>(status),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'timeMode': serializer.toJson<String>(timeMode),
      'alarmAddress': serializer.toJson<String?>(alarmAddress),
      'alarmReporter': serializer.toJson<String?>(alarmReporter),
      'alarmSpecialRights': serializer.toJson<bool?>(alarmSpecialRights),
      'alarmVehicles': serializer.toJson<String?>(alarmVehicles),
    };
  }

  Exercise copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? title,
    DateTime? date,
    int? startMinutes,
    Value<int?> endMinutes = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<String?> keywordId = const Value.absent(),
    String? goals,
    Value<String?> scenario = const Value.absent(),
    String? status,
    Value<String?> approvedBy = const Value.absent(),
    Value<DateTime?> approvedAt = const Value.absent(),
    String? timeMode,
    Value<String?> alarmAddress = const Value.absent(),
    Value<String?> alarmReporter = const Value.absent(),
    Value<bool?> alarmSpecialRights = const Value.absent(),
    Value<String?> alarmVehicles = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    date: date ?? this.date,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes.present ? endMinutes.value : this.endMinutes,
    location: location.present ? location.value : this.location,
    unit: unit.present ? unit.value : this.unit,
    topic: topic.present ? topic.value : this.topic,
    keywordId: keywordId.present ? keywordId.value : this.keywordId,
    goals: goals ?? this.goals,
    scenario: scenario.present ? scenario.value : this.scenario,
    status: status ?? this.status,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    timeMode: timeMode ?? this.timeMode,
    alarmAddress: alarmAddress.present ? alarmAddress.value : this.alarmAddress,
    alarmReporter: alarmReporter.present
        ? alarmReporter.value
        : this.alarmReporter,
    alarmSpecialRights: alarmSpecialRights.present
        ? alarmSpecialRights.value
        : this.alarmSpecialRights,
    alarmVehicles: alarmVehicles.present
        ? alarmVehicles.value
        : this.alarmVehicles,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      location: data.location.present ? data.location.value : this.location,
      unit: data.unit.present ? data.unit.value : this.unit,
      topic: data.topic.present ? data.topic.value : this.topic,
      keywordId: data.keywordId.present ? data.keywordId.value : this.keywordId,
      goals: data.goals.present ? data.goals.value : this.goals,
      scenario: data.scenario.present ? data.scenario.value : this.scenario,
      status: data.status.present ? data.status.value : this.status,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      timeMode: data.timeMode.present ? data.timeMode.value : this.timeMode,
      alarmAddress: data.alarmAddress.present
          ? data.alarmAddress.value
          : this.alarmAddress,
      alarmReporter: data.alarmReporter.present
          ? data.alarmReporter.value
          : this.alarmReporter,
      alarmSpecialRights: data.alarmSpecialRights.present
          ? data.alarmSpecialRights.value
          : this.alarmSpecialRights,
      alarmVehicles: data.alarmVehicles.present
          ? data.alarmVehicles.value
          : this.alarmVehicles,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('unit: $unit, ')
          ..write('topic: $topic, ')
          ..write('keywordId: $keywordId, ')
          ..write('goals: $goals, ')
          ..write('scenario: $scenario, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('timeMode: $timeMode, ')
          ..write('alarmAddress: $alarmAddress, ')
          ..write('alarmReporter: $alarmReporter, ')
          ..write('alarmSpecialRights: $alarmSpecialRights, ')
          ..write('alarmVehicles: $alarmVehicles')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    updatedAt,
    deleted,
    title,
    date,
    startMinutes,
    endMinutes,
    location,
    unit,
    topic,
    keywordId,
    goals,
    scenario,
    status,
    approvedBy,
    approvedAt,
    timeMode,
    alarmAddress,
    alarmReporter,
    alarmSpecialRights,
    alarmVehicles,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.date == this.date &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.location == this.location &&
          other.unit == this.unit &&
          other.topic == this.topic &&
          other.keywordId == this.keywordId &&
          other.goals == this.goals &&
          other.scenario == this.scenario &&
          other.status == this.status &&
          other.approvedBy == this.approvedBy &&
          other.approvedAt == this.approvedAt &&
          other.timeMode == this.timeMode &&
          other.alarmAddress == this.alarmAddress &&
          other.alarmReporter == this.alarmReporter &&
          other.alarmSpecialRights == this.alarmSpecialRights &&
          other.alarmVehicles == this.alarmVehicles);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<int> startMinutes;
  final Value<int?> endMinutes;
  final Value<String?> location;
  final Value<String?> unit;
  final Value<String?> topic;
  final Value<String?> keywordId;
  final Value<String> goals;
  final Value<String?> scenario;
  final Value<String> status;
  final Value<String?> approvedBy;
  final Value<DateTime?> approvedAt;
  final Value<String> timeMode;
  final Value<String?> alarmAddress;
  final Value<String?> alarmReporter;
  final Value<bool?> alarmSpecialRights;
  final Value<String?> alarmVehicles;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.unit = const Value.absent(),
    this.topic = const Value.absent(),
    this.keywordId = const Value.absent(),
    this.goals = const Value.absent(),
    this.scenario = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.timeMode = const Value.absent(),
    this.alarmAddress = const Value.absent(),
    this.alarmReporter = const Value.absent(),
    this.alarmSpecialRights = const Value.absent(),
    this.alarmVehicles = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String title,
    required DateTime date,
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.unit = const Value.absent(),
    this.topic = const Value.absent(),
    this.keywordId = const Value.absent(),
    this.goals = const Value.absent(),
    this.scenario = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.timeMode = const Value.absent(),
    this.alarmAddress = const Value.absent(),
    this.alarmReporter = const Value.absent(),
    this.alarmSpecialRights = const Value.absent(),
    this.alarmVehicles = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       date = Value(date);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? location,
    Expression<String>? unit,
    Expression<String>? topic,
    Expression<String>? keywordId,
    Expression<String>? goals,
    Expression<String>? scenario,
    Expression<String>? status,
    Expression<String>? approvedBy,
    Expression<DateTime>? approvedAt,
    Expression<String>? timeMode,
    Expression<String>? alarmAddress,
    Expression<String>? alarmReporter,
    Expression<bool>? alarmSpecialRights,
    Expression<String>? alarmVehicles,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (location != null) 'location': location,
      if (unit != null) 'unit': unit,
      if (topic != null) 'topic': topic,
      if (keywordId != null) 'keyword_id': keywordId,
      if (goals != null) 'goals': goals,
      if (scenario != null) 'scenario': scenario,
      if (status != null) 'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (timeMode != null) 'time_mode': timeMode,
      if (alarmAddress != null) 'alarm_address': alarmAddress,
      if (alarmReporter != null) 'alarm_reporter': alarmReporter,
      if (alarmSpecialRights != null)
        'alarm_special_rights': alarmSpecialRights,
      if (alarmVehicles != null) 'alarm_vehicles': alarmVehicles,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? title,
    Value<DateTime>? date,
    Value<int>? startMinutes,
    Value<int?>? endMinutes,
    Value<String?>? location,
    Value<String?>? unit,
    Value<String?>? topic,
    Value<String?>? keywordId,
    Value<String>? goals,
    Value<String?>? scenario,
    Value<String>? status,
    Value<String?>? approvedBy,
    Value<DateTime?>? approvedAt,
    Value<String>? timeMode,
    Value<String?>? alarmAddress,
    Value<String?>? alarmReporter,
    Value<bool?>? alarmSpecialRights,
    Value<String?>? alarmVehicles,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      location: location ?? this.location,
      unit: unit ?? this.unit,
      topic: topic ?? this.topic,
      keywordId: keywordId ?? this.keywordId,
      goals: goals ?? this.goals,
      scenario: scenario ?? this.scenario,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      timeMode: timeMode ?? this.timeMode,
      alarmAddress: alarmAddress ?? this.alarmAddress,
      alarmReporter: alarmReporter ?? this.alarmReporter,
      alarmSpecialRights: alarmSpecialRights ?? this.alarmSpecialRights,
      alarmVehicles: alarmVehicles ?? this.alarmVehicles,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (keywordId.present) {
      map['keyword_id'] = Variable<String>(keywordId.value);
    }
    if (goals.present) {
      map['goals'] = Variable<String>(goals.value);
    }
    if (scenario.present) {
      map['scenario'] = Variable<String>(scenario.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (timeMode.present) {
      map['time_mode'] = Variable<String>(timeMode.value);
    }
    if (alarmAddress.present) {
      map['alarm_address'] = Variable<String>(alarmAddress.value);
    }
    if (alarmReporter.present) {
      map['alarm_reporter'] = Variable<String>(alarmReporter.value);
    }
    if (alarmSpecialRights.present) {
      map['alarm_special_rights'] = Variable<bool>(alarmSpecialRights.value);
    }
    if (alarmVehicles.present) {
      map['alarm_vehicles'] = Variable<String>(alarmVehicles.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('unit: $unit, ')
          ..write('topic: $topic, ')
          ..write('keywordId: $keywordId, ')
          ..write('goals: $goals, ')
          ..write('scenario: $scenario, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('timeMode: $timeMode, ')
          ..write('alarmAddress: $alarmAddress, ')
          ..write('alarmReporter: $alarmReporter, ')
          ..write('alarmSpecialRights: $alarmSpecialRights, ')
          ..write('alarmVehicles: $alarmVehicles, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisePhasesTable extends ExercisePhases
    with TableInfo<$ExercisePhasesTable, ExercisePhase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisePhasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    exerciseId,
    offsetMinutes,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_phases';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExercisePhase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExercisePhase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExercisePhase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $ExercisePhasesTable createAlias(String alias) {
    return $ExercisePhasesTable(attachedDatabase, alias);
  }
}

class ExercisePhase extends DataClass implements Insertable<ExercisePhase> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String exerciseId;
  final int offsetMinutes;
  final String description;
  const ExercisePhase({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.exerciseId,
    required this.offsetMinutes,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['description'] = Variable<String>(description);
    return map;
  }

  ExercisePhasesCompanion toCompanion(bool nullToAbsent) {
    return ExercisePhasesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      exerciseId: Value(exerciseId),
      offsetMinutes: Value(offsetMinutes),
      description: Value(description),
    );
  }

  factory ExercisePhase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExercisePhase(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'description': serializer.toJson<String>(description),
    };
  }

  ExercisePhase copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? exerciseId,
    int? offsetMinutes,
    String? description,
  }) => ExercisePhase(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    exerciseId: exerciseId ?? this.exerciseId,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    description: description ?? this.description,
  );
  ExercisePhase copyWithCompanion(ExercisePhasesCompanion data) {
    return ExercisePhase(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExercisePhase(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    exerciseId,
    offsetMinutes,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExercisePhase &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.exerciseId == this.exerciseId &&
          other.offsetMinutes == this.offsetMinutes &&
          other.description == this.description);
}

class ExercisePhasesCompanion extends UpdateCompanion<ExercisePhase> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> exerciseId;
  final Value<int> offsetMinutes;
  final Value<String> description;
  final Value<int> rowid;
  const ExercisePhasesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisePhasesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String exerciseId,
    this.offsetMinutes = const Value.absent(),
    required String description,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       description = Value(description);
  static Insertable<ExercisePhase> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? exerciseId,
    Expression<int>? offsetMinutes,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisePhasesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? exerciseId,
    Value<int>? offsetMinutes,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return ExercisePhasesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      exerciseId: exerciseId ?? this.exerciseId,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisePhasesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseSafetyChecksTable extends ExerciseSafetyChecks
    with TableInfo<$ExerciseSafetyChecksTable, ExerciseSafetyCheck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSafetyChecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    exerciseId,
    description,
    checked,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_safety_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseSafetyCheck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseSafetyCheck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSafetyCheck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ExerciseSafetyChecksTable createAlias(String alias) {
    return $ExerciseSafetyChecksTable(attachedDatabase, alias);
  }
}

class ExerciseSafetyCheck extends DataClass
    implements Insertable<ExerciseSafetyCheck> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String exerciseId;
  final String description;
  final bool checked;
  final int sortOrder;
  const ExerciseSafetyCheck({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.exerciseId,
    required this.description,
    required this.checked,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['description'] = Variable<String>(description);
    map['checked'] = Variable<bool>(checked);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExerciseSafetyChecksCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSafetyChecksCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      exerciseId: Value(exerciseId),
      description: Value(description),
      checked: Value(checked),
      sortOrder: Value(sortOrder),
    );
  }

  factory ExerciseSafetyCheck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSafetyCheck(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      description: serializer.fromJson<String>(json['description']),
      checked: serializer.fromJson<bool>(json['checked']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'description': serializer.toJson<String>(description),
      'checked': serializer.toJson<bool>(checked),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ExerciseSafetyCheck copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? exerciseId,
    String? description,
    bool? checked,
    int? sortOrder,
  }) => ExerciseSafetyCheck(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    exerciseId: exerciseId ?? this.exerciseId,
    description: description ?? this.description,
    checked: checked ?? this.checked,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ExerciseSafetyCheck copyWithCompanion(ExerciseSafetyChecksCompanion data) {
    return ExerciseSafetyCheck(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      description: data.description.present
          ? data.description.value
          : this.description,
      checked: data.checked.present ? data.checked.value : this.checked,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSafetyCheck(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('description: $description, ')
          ..write('checked: $checked, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    exerciseId,
    description,
    checked,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSafetyCheck &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.exerciseId == this.exerciseId &&
          other.description == this.description &&
          other.checked == this.checked &&
          other.sortOrder == this.sortOrder);
}

class ExerciseSafetyChecksCompanion
    extends UpdateCompanion<ExerciseSafetyCheck> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> exerciseId;
  final Value<String> description;
  final Value<bool> checked;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ExerciseSafetyChecksCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.description = const Value.absent(),
    this.checked = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseSafetyChecksCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String exerciseId,
    required String description,
    this.checked = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       description = Value(description);
  static Insertable<ExerciseSafetyCheck> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? exerciseId,
    Expression<String>? description,
    Expression<bool>? checked,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (description != null) 'description': description,
      if (checked != null) 'checked': checked,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseSafetyChecksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? exerciseId,
    Value<String>? description,
    Value<bool>? checked,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ExerciseSafetyChecksCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      exerciseId: exerciseId ?? this.exerciseId,
      description: description ?? this.description,
      checked: checked ?? this.checked,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSafetyChecksCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('description: $description, ')
          ..write('checked: $checked, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseVehiclesTable extends ExerciseVehicles
    with TableInfo<$ExerciseVehiclesTable, ExerciseVehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseVehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<String> patternId = GeneratedColumn<String>(
    'pattern_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    exerciseId,
    vehicleId,
    patternId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseVehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseVehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseVehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ExerciseVehiclesTable createAlias(String alias) {
    return $ExerciseVehiclesTable(attachedDatabase, alias);
  }
}

class ExerciseVehicle extends DataClass implements Insertable<ExerciseVehicle> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String exerciseId;
  final String vehicleId;
  final String? patternId;
  final int sortOrder;
  const ExerciseVehicle({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.exerciseId,
    required this.vehicleId,
    this.patternId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['vehicle_id'] = Variable<String>(vehicleId);
    if (!nullToAbsent || patternId != null) {
      map['pattern_id'] = Variable<String>(patternId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExerciseVehiclesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseVehiclesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      exerciseId: Value(exerciseId),
      vehicleId: Value(vehicleId),
      patternId: patternId == null && nullToAbsent
          ? const Value.absent()
          : Value(patternId),
      sortOrder: Value(sortOrder),
    );
  }

  factory ExerciseVehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseVehicle(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      patternId: serializer.fromJson<String?>(json['patternId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'patternId': serializer.toJson<String?>(patternId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ExerciseVehicle copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? exerciseId,
    String? vehicleId,
    Value<String?> patternId = const Value.absent(),
    int? sortOrder,
  }) => ExerciseVehicle(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    exerciseId: exerciseId ?? this.exerciseId,
    vehicleId: vehicleId ?? this.vehicleId,
    patternId: patternId.present ? patternId.value : this.patternId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ExerciseVehicle copyWithCompanion(ExerciseVehiclesCompanion data) {
    return ExerciseVehicle(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseVehicle(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('patternId: $patternId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    exerciseId,
    vehicleId,
    patternId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseVehicle &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.exerciseId == this.exerciseId &&
          other.vehicleId == this.vehicleId &&
          other.patternId == this.patternId &&
          other.sortOrder == this.sortOrder);
}

class ExerciseVehiclesCompanion extends UpdateCompanion<ExerciseVehicle> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> exerciseId;
  final Value<String> vehicleId;
  final Value<String?> patternId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ExerciseVehiclesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.patternId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseVehiclesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String exerciseId,
    required String vehicleId,
    this.patternId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       vehicleId = Value(vehicleId);
  static Insertable<ExerciseVehicle> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? exerciseId,
    Expression<String>? vehicleId,
    Expression<String>? patternId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (patternId != null) 'pattern_id': patternId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseVehiclesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? exerciseId,
    Value<String>? vehicleId,
    Value<String?>? patternId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ExerciseVehiclesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      exerciseId: exerciseId ?? this.exerciseId,
      vehicleId: vehicleId ?? this.vehicleId,
      patternId: patternId ?? this.patternId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<String>(patternId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseVehiclesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('patternId: $patternId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAssignmentsTable extends ExerciseAssignments
    with TableInfo<$ExerciseAssignmentsTable, ExerciseAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _functionIdMeta = const VerificationMeta(
    'functionId',
  );
  @override
  late final GeneratedColumn<String> functionId = GeneratedColumn<String>(
    'function_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    exerciseId,
    functionId,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('function_id')) {
      context.handle(
        _functionIdMeta,
        functionId.isAcceptableOrUnknown(data['function_id']!, _functionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_functionIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAssignment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      functionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}function_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $ExerciseAssignmentsTable createAlias(String alias) {
    return $ExerciseAssignmentsTable(attachedDatabase, alias);
  }
}

class ExerciseAssignment extends DataClass
    implements Insertable<ExerciseAssignment> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String exerciseId;
  final String functionId;
  final String personId;
  const ExerciseAssignment({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.exerciseId,
    required this.functionId,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['function_id'] = Variable<String>(functionId);
    map['person_id'] = Variable<String>(personId);
    return map;
  }

  ExerciseAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAssignmentsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      exerciseId: Value(exerciseId),
      functionId: Value(functionId),
      personId: Value(personId),
    );
  }

  factory ExerciseAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAssignment(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      functionId: serializer.fromJson<String>(json['functionId']),
      personId: serializer.fromJson<String>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'functionId': serializer.toJson<String>(functionId),
      'personId': serializer.toJson<String>(personId),
    };
  }

  ExerciseAssignment copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? exerciseId,
    String? functionId,
    String? personId,
  }) => ExerciseAssignment(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    exerciseId: exerciseId ?? this.exerciseId,
    functionId: functionId ?? this.functionId,
    personId: personId ?? this.personId,
  );
  ExerciseAssignment copyWithCompanion(ExerciseAssignmentsCompanion data) {
    return ExerciseAssignment(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      functionId: data.functionId.present
          ? data.functionId.value
          : this.functionId,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAssignment(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('functionId: $functionId, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deleted, exerciseId, functionId, personId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAssignment &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.exerciseId == this.exerciseId &&
          other.functionId == this.functionId &&
          other.personId == this.personId);
}

class ExerciseAssignmentsCompanion extends UpdateCompanion<ExerciseAssignment> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> exerciseId;
  final Value<String> functionId;
  final Value<String> personId;
  final Value<int> rowid;
  const ExerciseAssignmentsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.functionId = const Value.absent(),
    this.personId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String exerciseId,
    required String functionId,
    required String personId,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       functionId = Value(functionId),
       personId = Value(personId);
  static Insertable<ExerciseAssignment> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? exerciseId,
    Expression<String>? functionId,
    Expression<String>? personId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (functionId != null) 'function_id': functionId,
      if (personId != null) 'person_id': personId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseAssignmentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? exerciseId,
    Value<String>? functionId,
    Value<String>? personId,
    Value<int>? rowid,
  }) {
    return ExerciseAssignmentsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      exerciseId: exerciseId ?? this.exerciseId,
      functionId: functionId ?? this.functionId,
      personId: personId ?? this.personId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (functionId.present) {
      map['function_id'] = Variable<String>(functionId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('functionId: $functionId, ')
          ..write('personId: $personId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmPlanEntriesTable extends AlarmPlanEntries
    with TableInfo<$AlarmPlanEntriesTable, AlarmPlanEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmPlanEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fahrzeug'),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmOffsetMeta = const VerificationMeta(
    'alarmOffset',
  );
  @override
  late final GeneratedColumn<int> alarmOffset = GeneratedColumn<int>(
    'alarm_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departOffsetMeta = const VerificationMeta(
    'departOffset',
  );
  @override
  late final GeneratedColumn<int> departOffset = GeneratedColumn<int>(
    'depart_offset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _arriveOffsetMeta = const VerificationMeta(
    'arriveOffset',
  );
  @override
  late final GeneratedColumn<int> arriveOffset = GeneratedColumn<int>(
    'arrive_offset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    exerciseId,
    label,
    kind,
    vehicleId,
    alarmOffset,
    departOffset,
    arriveOffset,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarm_plan_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmPlanEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    }
    if (data.containsKey('alarm_offset')) {
      context.handle(
        _alarmOffsetMeta,
        alarmOffset.isAcceptableOrUnknown(
          data['alarm_offset']!,
          _alarmOffsetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_alarmOffsetMeta);
    }
    if (data.containsKey('depart_offset')) {
      context.handle(
        _departOffsetMeta,
        departOffset.isAcceptableOrUnknown(
          data['depart_offset']!,
          _departOffsetMeta,
        ),
      );
    }
    if (data.containsKey('arrive_offset')) {
      context.handle(
        _arriveOffsetMeta,
        arriveOffset.isAcceptableOrUnknown(
          data['arrive_offset']!,
          _arriveOffsetMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmPlanEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmPlanEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      ),
      alarmOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alarm_offset'],
      )!,
      departOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depart_offset'],
      ),
      arriveOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arrive_offset'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AlarmPlanEntriesTable createAlias(String alias) {
    return $AlarmPlanEntriesTable(attachedDatabase, alias);
  }
}

class AlarmPlanEntry extends DataClass implements Insertable<AlarmPlanEntry> {
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final String exerciseId;
  final String label;

  /// `fahrzeug`, `boot` oder `trupp`
  final String kind;
  final String? vehicleId;
  final int alarmOffset;
  final int? departOffset;
  final int? arriveOffset;
  final String? note;
  final int sortOrder;
  const AlarmPlanEntry({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.exerciseId,
    required this.label,
    required this.kind,
    this.vehicleId,
    required this.alarmOffset,
    this.departOffset,
    this.arriveOffset,
    this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['label'] = Variable<String>(label);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || vehicleId != null) {
      map['vehicle_id'] = Variable<String>(vehicleId);
    }
    map['alarm_offset'] = Variable<int>(alarmOffset);
    if (!nullToAbsent || departOffset != null) {
      map['depart_offset'] = Variable<int>(departOffset);
    }
    if (!nullToAbsent || arriveOffset != null) {
      map['arrive_offset'] = Variable<int>(arriveOffset);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AlarmPlanEntriesCompanion toCompanion(bool nullToAbsent) {
    return AlarmPlanEntriesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      exerciseId: Value(exerciseId),
      label: Value(label),
      kind: Value(kind),
      vehicleId: vehicleId == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleId),
      alarmOffset: Value(alarmOffset),
      departOffset: departOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(departOffset),
      arriveOffset: arriveOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(arriveOffset),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory AlarmPlanEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmPlanEntry(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      label: serializer.fromJson<String>(json['label']),
      kind: serializer.fromJson<String>(json['kind']),
      vehicleId: serializer.fromJson<String?>(json['vehicleId']),
      alarmOffset: serializer.fromJson<int>(json['alarmOffset']),
      departOffset: serializer.fromJson<int?>(json['departOffset']),
      arriveOffset: serializer.fromJson<int?>(json['arriveOffset']),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<String>(kind),
      'vehicleId': serializer.toJson<String?>(vehicleId),
      'alarmOffset': serializer.toJson<int>(alarmOffset),
      'departOffset': serializer.toJson<int?>(departOffset),
      'arriveOffset': serializer.toJson<int?>(arriveOffset),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AlarmPlanEntry copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? exerciseId,
    String? label,
    String? kind,
    Value<String?> vehicleId = const Value.absent(),
    int? alarmOffset,
    Value<int?> departOffset = const Value.absent(),
    Value<int?> arriveOffset = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? sortOrder,
  }) => AlarmPlanEntry(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    exerciseId: exerciseId ?? this.exerciseId,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    vehicleId: vehicleId.present ? vehicleId.value : this.vehicleId,
    alarmOffset: alarmOffset ?? this.alarmOffset,
    departOffset: departOffset.present ? departOffset.value : this.departOffset,
    arriveOffset: arriveOffset.present ? arriveOffset.value : this.arriveOffset,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AlarmPlanEntry copyWithCompanion(AlarmPlanEntriesCompanion data) {
    return AlarmPlanEntry(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      alarmOffset: data.alarmOffset.present
          ? data.alarmOffset.value
          : this.alarmOffset,
      departOffset: data.departOffset.present
          ? data.departOffset.value
          : this.departOffset,
      arriveOffset: data.arriveOffset.present
          ? data.arriveOffset.value
          : this.arriveOffset,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmPlanEntry(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('alarmOffset: $alarmOffset, ')
          ..write('departOffset: $departOffset, ')
          ..write('arriveOffset: $arriveOffset, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    exerciseId,
    label,
    kind,
    vehicleId,
    alarmOffset,
    departOffset,
    arriveOffset,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmPlanEntry &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.exerciseId == this.exerciseId &&
          other.label == this.label &&
          other.kind == this.kind &&
          other.vehicleId == this.vehicleId &&
          other.alarmOffset == this.alarmOffset &&
          other.departOffset == this.departOffset &&
          other.arriveOffset == this.arriveOffset &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class AlarmPlanEntriesCompanion extends UpdateCompanion<AlarmPlanEntry> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> exerciseId;
  final Value<String> label;
  final Value<String> kind;
  final Value<String?> vehicleId;
  final Value<int> alarmOffset;
  final Value<int?> departOffset;
  final Value<int?> arriveOffset;
  final Value<String?> note;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AlarmPlanEntriesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.alarmOffset = const Value.absent(),
    this.departOffset = const Value.absent(),
    this.arriveOffset = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmPlanEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    required String exerciseId,
    required String label,
    this.kind = const Value.absent(),
    this.vehicleId = const Value.absent(),
    required int alarmOffset,
    this.departOffset = const Value.absent(),
    this.arriveOffset = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       label = Value(label),
       alarmOffset = Value(alarmOffset);
  static Insertable<AlarmPlanEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? exerciseId,
    Expression<String>? label,
    Expression<String>? kind,
    Expression<String>? vehicleId,
    Expression<int>? alarmOffset,
    Expression<int>? departOffset,
    Expression<int>? arriveOffset,
    Expression<String>? note,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (alarmOffset != null) 'alarm_offset': alarmOffset,
      if (departOffset != null) 'depart_offset': departOffset,
      if (arriveOffset != null) 'arrive_offset': arriveOffset,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmPlanEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? exerciseId,
    Value<String>? label,
    Value<String>? kind,
    Value<String?>? vehicleId,
    Value<int>? alarmOffset,
    Value<int?>? departOffset,
    Value<int?>? arriveOffset,
    Value<String?>? note,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AlarmPlanEntriesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      exerciseId: exerciseId ?? this.exerciseId,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      vehicleId: vehicleId ?? this.vehicleId,
      alarmOffset: alarmOffset ?? this.alarmOffset,
      departOffset: departOffset ?? this.departOffset,
      arriveOffset: arriveOffset ?? this.arriveOffset,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (alarmOffset.present) {
      map['alarm_offset'] = Variable<int>(alarmOffset.value);
    }
    if (departOffset.present) {
      map['depart_offset'] = Variable<int>(departOffset.value);
    }
    if (arriveOffset.present) {
      map['arrive_offset'] = Variable<int>(arriveOffset.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmPlanEntriesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('alarmOffset: $alarmOffset, ')
          ..write('departOffset: $departOffset, ')
          ..write('arriveOffset: $arriveOffset, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $QualificationsTable qualifications = $QualificationsTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $PersonQualificationsTable personQualifications =
      $PersonQualificationsTable(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $CrewFunctionsTable crewFunctions = $CrewFunctionsTable(this);
  late final $CrewPatternsTable crewPatterns = $CrewPatternsTable(this);
  late final $CrewPatternFunctionsTable crewPatternFunctions =
      $CrewPatternFunctionsTable(this);
  late final $KeywordsTable keywords = $KeywordsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExercisePhasesTable exercisePhases = $ExercisePhasesTable(this);
  late final $ExerciseSafetyChecksTable exerciseSafetyChecks =
      $ExerciseSafetyChecksTable(this);
  late final $ExerciseVehiclesTable exerciseVehicles = $ExerciseVehiclesTable(
    this,
  );
  late final $ExerciseAssignmentsTable exerciseAssignments =
      $ExerciseAssignmentsTable(this);
  late final $AlarmPlanEntriesTable alarmPlanEntries = $AlarmPlanEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    qualifications,
    persons,
    personQualifications,
    vehicles,
    crewFunctions,
    crewPatterns,
    crewPatternFunctions,
    keywords,
    exercises,
    exercisePhases,
    exerciseSafetyChecks,
    exerciseVehicles,
    exerciseAssignments,
    alarmPlanEntries,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$QualificationsTableCreateCompanionBuilder =
    QualificationsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$QualificationsTableUpdateCompanionBuilder =
    QualificationsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$QualificationsTableFilterComposer
    extends Composer<_$AppDatabase, $QualificationsTable> {
  $$QualificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QualificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $QualificationsTable> {
  $$QualificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QualificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QualificationsTable> {
  $$QualificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$QualificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QualificationsTable,
          Qualification,
          $$QualificationsTableFilterComposer,
          $$QualificationsTableOrderingComposer,
          $$QualificationsTableAnnotationComposer,
          $$QualificationsTableCreateCompanionBuilder,
          $$QualificationsTableUpdateCompanionBuilder,
          (
            Qualification,
            BaseReferences<_$AppDatabase, $QualificationsTable, Qualification>,
          ),
          Qualification,
          PrefetchHooks Function()
        > {
  $$QualificationsTableTableManager(
    _$AppDatabase db,
    $QualificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QualificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QualificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QualificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QualificationsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QualificationsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QualificationsTable, Qualification>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $QualificationsTable,
                    Qualification
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QualificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QualificationsTable,
      Qualification,
      $$QualificationsTableFilterComposer,
      $$QualificationsTableOrderingComposer,
      $$QualificationsTableAnnotationComposer,
      $$QualificationsTableCreateCompanionBuilder,
      $$QualificationsTableUpdateCompanionBuilder,
      (
        Qualification,
        BaseReferences<_$AppDatabase, $QualificationsTable, Qualification>,
      ),
      Qualification,
      PrefetchHooks Function()
    >;
typedef $$PersonsTableCreateCompanionBuilder = PersonsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  required String lastName,
  Value<String> firstName,
  Value<String?> personnelNo,
  Value<bool> youth,
  Value<int> rowid,
});
typedef $$PersonsTableUpdateCompanionBuilder = PersonsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<String> lastName,
  Value<String> firstName,
  Value<String?> personnelNo,
  Value<bool> youth,
  Value<int> rowid,
});

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personnelNo => $composableBuilder(
    column: $table.personnelNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get youth => $composableBuilder(
    column: $table.youth,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personnelNo => $composableBuilder(
    column: $table.personnelNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get youth => $composableBuilder(
    column: $table.youth,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get personnelNo => $composableBuilder(
    column: $table.personnelNo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get youth =>
      $composableBuilder(column: $table.youth, builder: (column) => column);
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String?> personnelNo = const Value.absent(),
                Value<bool> youth = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                lastName: lastName,
                firstName: firstName,
                personnelNo: personnelNo,
                youth: youth,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String lastName,
                Value<String> firstName = const Value.absent(),
                Value<String?> personnelNo = const Value.absent(),
                Value<bool> youth = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                lastName: lastName,
                firstName: firstName,
                personnelNo: personnelNo,
                youth: youth,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonsTable, Person>(table),
                  BaseReferences<_$AppDatabase, $PersonsTable, Person>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$PersonQualificationsTableCreateCompanionBuilder =
    PersonQualificationsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String personId,
      required String qualificationId,
      Value<int> rowid,
    });
typedef $$PersonQualificationsTableUpdateCompanionBuilder =
    PersonQualificationsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> personId,
      Value<String> qualificationId,
      Value<int> rowid,
    });

class $$PersonQualificationsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonQualificationsTable> {
  $$PersonQualificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualificationId => $composableBuilder(
    column: $table.qualificationId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonQualificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonQualificationsTable> {
  $$PersonQualificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualificationId => $composableBuilder(
    column: $table.qualificationId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonQualificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonQualificationsTable> {
  $$PersonQualificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get qualificationId => $composableBuilder(
    column: $table.qualificationId,
    builder: (column) => column,
  );
}

class $$PersonQualificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonQualificationsTable,
          PersonQualification,
          $$PersonQualificationsTableFilterComposer,
          $$PersonQualificationsTableOrderingComposer,
          $$PersonQualificationsTableAnnotationComposer,
          $$PersonQualificationsTableCreateCompanionBuilder,
          $$PersonQualificationsTableUpdateCompanionBuilder,
          (
            PersonQualification,
            BaseReferences<
              _$AppDatabase,
              $PersonQualificationsTable,
              PersonQualification
            >,
          ),
          PersonQualification,
          PrefetchHooks Function()
        > {
  $$PersonQualificationsTableTableManager(
    _$AppDatabase db,
    $PersonQualificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonQualificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonQualificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersonQualificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> qualificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonQualificationsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                personId: personId,
                qualificationId: qualificationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String personId,
                required String qualificationId,
                Value<int> rowid = const Value.absent(),
              }) => PersonQualificationsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                personId: personId,
                qualificationId: qualificationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonQualificationsTable, PersonQualification>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PersonQualificationsTable,
                    PersonQualification
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonQualificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonQualificationsTable,
      PersonQualification,
      $$PersonQualificationsTableFilterComposer,
      $$PersonQualificationsTableOrderingComposer,
      $$PersonQualificationsTableAnnotationComposer,
      $$PersonQualificationsTableCreateCompanionBuilder,
      $$PersonQualificationsTableUpdateCompanionBuilder,
      (
        PersonQualification,
        BaseReferences<
          _$AppDatabase,
          $PersonQualificationsTable,
          PersonQualification
        >,
      ),
      PersonQualification,
      PrefetchHooks Function()
    >;
typedef $$VehiclesTableCreateCompanionBuilder = VehiclesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  required String name,
  Value<String?> type,
  Value<String> kind,
  Value<String?> callSign,
  Value<String> status,
  Value<String?> externalId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$VehiclesTableUpdateCompanionBuilder = VehiclesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<String> name,
  Value<String?> type,
  Value<String> kind,
  Value<String?> callSign,
  Value<String> status,
  Value<String?> externalId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callSign => $composableBuilder(
    column: $table.callSign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callSign => $composableBuilder(
    column: $table.callSign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get callSign =>
      $composableBuilder(column: $table.callSign, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          Vehicle,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
          Vehicle,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> callSign = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                type: type,
                kind: kind,
                callSign: callSign,
                status: status,
                externalId: externalId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<String?> type = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> callSign = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                type: type,
                kind: kind,
                callSign: callSign,
                status: status,
                externalId: externalId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, Vehicle>(table),
                  BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      Vehicle,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
      Vehicle,
      PrefetchHooks Function()
    >;
typedef $$CrewFunctionsTableCreateCompanionBuilder =
    CrewFunctionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String?> vehicleId,
      required String name,
      Value<String?> requiredQualificationId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CrewFunctionsTableUpdateCompanionBuilder =
    CrewFunctionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String?> vehicleId,
      Value<String> name,
      Value<String?> requiredQualificationId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CrewFunctionsTableFilterComposer
    extends Composer<_$AppDatabase, $CrewFunctionsTable> {
  $$CrewFunctionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredQualificationId => $composableBuilder(
    column: $table.requiredQualificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CrewFunctionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CrewFunctionsTable> {
  $$CrewFunctionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredQualificationId => $composableBuilder(
    column: $table.requiredQualificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CrewFunctionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrewFunctionsTable> {
  $$CrewFunctionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get requiredQualificationId => $composableBuilder(
    column: $table.requiredQualificationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CrewFunctionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CrewFunctionsTable,
          CrewFunction,
          $$CrewFunctionsTableFilterComposer,
          $$CrewFunctionsTableOrderingComposer,
          $$CrewFunctionsTableAnnotationComposer,
          $$CrewFunctionsTableCreateCompanionBuilder,
          $$CrewFunctionsTableUpdateCompanionBuilder,
          (
            CrewFunction,
            BaseReferences<_$AppDatabase, $CrewFunctionsTable, CrewFunction>,
          ),
          CrewFunction,
          PrefetchHooks Function()
        > {
  $$CrewFunctionsTableTableManager(_$AppDatabase db, $CrewFunctionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrewFunctionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrewFunctionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrewFunctionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> vehicleId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> requiredQualificationId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrewFunctionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                vehicleId: vehicleId,
                name: name,
                requiredQualificationId: requiredQualificationId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> vehicleId = const Value.absent(),
                required String name,
                Value<String?> requiredQualificationId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrewFunctionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                vehicleId: vehicleId,
                name: name,
                requiredQualificationId: requiredQualificationId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CrewFunctionsTable, CrewFunction>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CrewFunctionsTable,
                    CrewFunction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CrewFunctionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CrewFunctionsTable,
      CrewFunction,
      $$CrewFunctionsTableFilterComposer,
      $$CrewFunctionsTableOrderingComposer,
      $$CrewFunctionsTableAnnotationComposer,
      $$CrewFunctionsTableCreateCompanionBuilder,
      $$CrewFunctionsTableUpdateCompanionBuilder,
      (
        CrewFunction,
        BaseReferences<_$AppDatabase, $CrewFunctionsTable, CrewFunction>,
      ),
      CrewFunction,
      PrefetchHooks Function()
    >;
typedef $$CrewPatternsTableCreateCompanionBuilder =
    CrewPatternsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String vehicleId,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CrewPatternsTableUpdateCompanionBuilder =
    CrewPatternsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> vehicleId,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CrewPatternsTableFilterComposer
    extends Composer<_$AppDatabase, $CrewPatternsTable> {
  $$CrewPatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CrewPatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $CrewPatternsTable> {
  $$CrewPatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CrewPatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrewPatternsTable> {
  $$CrewPatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CrewPatternsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CrewPatternsTable,
          CrewPattern,
          $$CrewPatternsTableFilterComposer,
          $$CrewPatternsTableOrderingComposer,
          $$CrewPatternsTableAnnotationComposer,
          $$CrewPatternsTableCreateCompanionBuilder,
          $$CrewPatternsTableUpdateCompanionBuilder,
          (
            CrewPattern,
            BaseReferences<_$AppDatabase, $CrewPatternsTable, CrewPattern>,
          ),
          CrewPattern,
          PrefetchHooks Function()
        > {
  $$CrewPatternsTableTableManager(_$AppDatabase db, $CrewPatternsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrewPatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrewPatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrewPatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrewPatternsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                vehicleId: vehicleId,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String vehicleId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrewPatternsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                vehicleId: vehicleId,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CrewPatternsTable, CrewPattern>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CrewPatternsTable,
                    CrewPattern
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CrewPatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CrewPatternsTable,
      CrewPattern,
      $$CrewPatternsTableFilterComposer,
      $$CrewPatternsTableOrderingComposer,
      $$CrewPatternsTableAnnotationComposer,
      $$CrewPatternsTableCreateCompanionBuilder,
      $$CrewPatternsTableUpdateCompanionBuilder,
      (
        CrewPattern,
        BaseReferences<_$AppDatabase, $CrewPatternsTable, CrewPattern>,
      ),
      CrewPattern,
      PrefetchHooks Function()
    >;
typedef $$CrewPatternFunctionsTableCreateCompanionBuilder =
    CrewPatternFunctionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String patternId,
      required String functionId,
      Value<int> rowid,
    });
typedef $$CrewPatternFunctionsTableUpdateCompanionBuilder =
    CrewPatternFunctionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> patternId,
      Value<String> functionId,
      Value<int> rowid,
    });

class $$CrewPatternFunctionsTableFilterComposer
    extends Composer<_$AppDatabase, $CrewPatternFunctionsTable> {
  $$CrewPatternFunctionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CrewPatternFunctionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CrewPatternFunctionsTable> {
  $$CrewPatternFunctionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CrewPatternFunctionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrewPatternFunctionsTable> {
  $$CrewPatternFunctionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get patternId =>
      $composableBuilder(column: $table.patternId, builder: (column) => column);

  GeneratedColumn<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => column,
  );
}

class $$CrewPatternFunctionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CrewPatternFunctionsTable,
          CrewPatternFunction,
          $$CrewPatternFunctionsTableFilterComposer,
          $$CrewPatternFunctionsTableOrderingComposer,
          $$CrewPatternFunctionsTableAnnotationComposer,
          $$CrewPatternFunctionsTableCreateCompanionBuilder,
          $$CrewPatternFunctionsTableUpdateCompanionBuilder,
          (
            CrewPatternFunction,
            BaseReferences<
              _$AppDatabase,
              $CrewPatternFunctionsTable,
              CrewPatternFunction
            >,
          ),
          CrewPatternFunction,
          PrefetchHooks Function()
        > {
  $$CrewPatternFunctionsTableTableManager(
    _$AppDatabase db,
    $CrewPatternFunctionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrewPatternFunctionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrewPatternFunctionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CrewPatternFunctionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> patternId = const Value.absent(),
                Value<String> functionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrewPatternFunctionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                patternId: patternId,
                functionId: functionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String patternId,
                required String functionId,
                Value<int> rowid = const Value.absent(),
              }) => CrewPatternFunctionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                patternId: patternId,
                functionId: functionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CrewPatternFunctionsTable, CrewPatternFunction>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CrewPatternFunctionsTable,
                    CrewPatternFunction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CrewPatternFunctionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CrewPatternFunctionsTable,
      CrewPatternFunction,
      $$CrewPatternFunctionsTableFilterComposer,
      $$CrewPatternFunctionsTableOrderingComposer,
      $$CrewPatternFunctionsTableAnnotationComposer,
      $$CrewPatternFunctionsTableCreateCompanionBuilder,
      $$CrewPatternFunctionsTableUpdateCompanionBuilder,
      (
        CrewPatternFunction,
        BaseReferences<
          _$AppDatabase,
          $CrewPatternFunctionsTable,
          CrewPatternFunction
        >,
      ),
      CrewPatternFunction,
      PrefetchHooks Function()
    >;
typedef $$KeywordsTableCreateCompanionBuilder = KeywordsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  required String code,
  Value<String?> category,
  Value<String?> description,
  Value<String?> resources,
  Value<bool> specialRights,
  Value<int> rowid,
});
typedef $$KeywordsTableUpdateCompanionBuilder = KeywordsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<String> code,
  Value<String?> category,
  Value<String?> description,
  Value<String?> resources,
  Value<bool> specialRights,
  Value<int> rowid,
});

class $$KeywordsTableFilterComposer
    extends Composer<_$AppDatabase, $KeywordsTable> {
  $$KeywordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resources => $composableBuilder(
    column: $table.resources,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get specialRights => $composableBuilder(
    column: $table.specialRights,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeywordsTableOrderingComposer
    extends Composer<_$AppDatabase, $KeywordsTable> {
  $$KeywordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resources => $composableBuilder(
    column: $table.resources,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get specialRights => $composableBuilder(
    column: $table.specialRights,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeywordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeywordsTable> {
  $$KeywordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resources =>
      $composableBuilder(column: $table.resources, builder: (column) => column);

  GeneratedColumn<bool> get specialRights => $composableBuilder(
    column: $table.specialRights,
    builder: (column) => column,
  );
}

class $$KeywordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeywordsTable,
          Keyword,
          $$KeywordsTableFilterComposer,
          $$KeywordsTableOrderingComposer,
          $$KeywordsTableAnnotationComposer,
          $$KeywordsTableCreateCompanionBuilder,
          $$KeywordsTableUpdateCompanionBuilder,
          (Keyword, BaseReferences<_$AppDatabase, $KeywordsTable, Keyword>),
          Keyword,
          PrefetchHooks Function()
        > {
  $$KeywordsTableTableManager(_$AppDatabase db, $KeywordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeywordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeywordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeywordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> resources = const Value.absent(),
                Value<bool> specialRights = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeywordsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                code: code,
                category: category,
                description: description,
                resources: resources,
                specialRights: specialRights,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String code,
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> resources = const Value.absent(),
                Value<bool> specialRights = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeywordsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                code: code,
                category: category,
                description: description,
                resources: resources,
                specialRights: specialRights,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeywordsTable, Keyword>(table),
                  BaseReferences<_$AppDatabase, $KeywordsTable, Keyword>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeywordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeywordsTable,
      Keyword,
      $$KeywordsTableFilterComposer,
      $$KeywordsTableOrderingComposer,
      $$KeywordsTableAnnotationComposer,
      $$KeywordsTableCreateCompanionBuilder,
      $$KeywordsTableUpdateCompanionBuilder,
      (Keyword, BaseReferences<_$AppDatabase, $KeywordsTable, Keyword>),
      Keyword,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  required String title,
  required DateTime date,
  Value<int> startMinutes,
  Value<int?> endMinutes,
  Value<String?> location,
  Value<String?> unit,
  Value<String?> topic,
  Value<String?> keywordId,
  Value<String> goals,
  Value<String?> scenario,
  Value<String> status,
  Value<String?> approvedBy,
  Value<DateTime?> approvedAt,
  Value<String> timeMode,
  Value<String?> alarmAddress,
  Value<String?> alarmReporter,
  Value<bool?> alarmSpecialRights,
  Value<String?> alarmVehicles,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<String> title,
  Value<DateTime> date,
  Value<int> startMinutes,
  Value<int?> endMinutes,
  Value<String?> location,
  Value<String?> unit,
  Value<String?> topic,
  Value<String?> keywordId,
  Value<String> goals,
  Value<String?> scenario,
  Value<String> status,
  Value<String?> approvedBy,
  Value<DateTime?> approvedAt,
  Value<String> timeMode,
  Value<String?> alarmAddress,
  Value<String?> alarmReporter,
  Value<bool?> alarmSpecialRights,
  Value<String?> alarmVehicles,
  Value<int> rowid,
});

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywordId => $composableBuilder(
    column: $table.keywordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scenario => $composableBuilder(
    column: $table.scenario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeMode => $composableBuilder(
    column: $table.timeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmAddress => $composableBuilder(
    column: $table.alarmAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmReporter => $composableBuilder(
    column: $table.alarmReporter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarmSpecialRights => $composableBuilder(
    column: $table.alarmSpecialRights,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmVehicles => $composableBuilder(
    column: $table.alarmVehicles,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywordId => $composableBuilder(
    column: $table.keywordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scenario => $composableBuilder(
    column: $table.scenario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeMode => $composableBuilder(
    column: $table.timeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmAddress => $composableBuilder(
    column: $table.alarmAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmReporter => $composableBuilder(
    column: $table.alarmReporter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarmSpecialRights => $composableBuilder(
    column: $table.alarmSpecialRights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmVehicles => $composableBuilder(
    column: $table.alarmVehicles,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get keywordId =>
      $composableBuilder(column: $table.keywordId, builder: (column) => column);

  GeneratedColumn<String> get goals =>
      $composableBuilder(column: $table.goals, builder: (column) => column);

  GeneratedColumn<String> get scenario =>
      $composableBuilder(column: $table.scenario, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeMode =>
      $composableBuilder(column: $table.timeMode, builder: (column) => column);

  GeneratedColumn<String> get alarmAddress => $composableBuilder(
    column: $table.alarmAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmReporter => $composableBuilder(
    column: $table.alarmReporter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alarmSpecialRights => $composableBuilder(
    column: $table.alarmSpecialRights,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmVehicles => $composableBuilder(
    column: $table.alarmVehicles,
    builder: (column) => column,
  );
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int?> endMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> keywordId = const Value.absent(),
                Value<String> goals = const Value.absent(),
                Value<String?> scenario = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String> timeMode = const Value.absent(),
                Value<String?> alarmAddress = const Value.absent(),
                Value<String?> alarmReporter = const Value.absent(),
                Value<bool?> alarmSpecialRights = const Value.absent(),
                Value<String?> alarmVehicles = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                title: title,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                unit: unit,
                topic: topic,
                keywordId: keywordId,
                goals: goals,
                scenario: scenario,
                status: status,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                timeMode: timeMode,
                alarmAddress: alarmAddress,
                alarmReporter: alarmReporter,
                alarmSpecialRights: alarmSpecialRights,
                alarmVehicles: alarmVehicles,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String title,
                required DateTime date,
                Value<int> startMinutes = const Value.absent(),
                Value<int?> endMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> keywordId = const Value.absent(),
                Value<String> goals = const Value.absent(),
                Value<String?> scenario = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String> timeMode = const Value.absent(),
                Value<String?> alarmAddress = const Value.absent(),
                Value<String?> alarmReporter = const Value.absent(),
                Value<bool?> alarmSpecialRights = const Value.absent(),
                Value<String?> alarmVehicles = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                title: title,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                unit: unit,
                topic: topic,
                keywordId: keywordId,
                goals: goals,
                scenario: scenario,
                status: status,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                timeMode: timeMode,
                alarmAddress: alarmAddress,
                alarmReporter: alarmReporter,
                alarmSpecialRights: alarmSpecialRights,
                alarmVehicles: alarmVehicles,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$ExercisePhasesTableCreateCompanionBuilder =
    ExercisePhasesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String exerciseId,
      Value<int> offsetMinutes,
      required String description,
      Value<int> rowid,
    });
typedef $$ExercisePhasesTableUpdateCompanionBuilder =
    ExercisePhasesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> exerciseId,
      Value<int> offsetMinutes,
      Value<String> description,
      Value<int> rowid,
    });

class $$ExercisePhasesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisePhasesTable> {
  $$ExercisePhasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisePhasesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisePhasesTable> {
  $$ExercisePhasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisePhasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisePhasesTable> {
  $$ExercisePhasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$ExercisePhasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisePhasesTable,
          ExercisePhase,
          $$ExercisePhasesTableFilterComposer,
          $$ExercisePhasesTableOrderingComposer,
          $$ExercisePhasesTableAnnotationComposer,
          $$ExercisePhasesTableCreateCompanionBuilder,
          $$ExercisePhasesTableUpdateCompanionBuilder,
          (
            ExercisePhase,
            BaseReferences<_$AppDatabase, $ExercisePhasesTable, ExercisePhase>,
          ),
          ExercisePhase,
          PrefetchHooks Function()
        > {
  $$ExercisePhasesTableTableManager(
    _$AppDatabase db,
    $ExercisePhasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisePhasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisePhasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisePhasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisePhasesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                offsetMinutes: offsetMinutes,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String exerciseId,
                Value<int> offsetMinutes = const Value.absent(),
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => ExercisePhasesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                offsetMinutes: offsetMinutes,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisePhasesTable, ExercisePhase>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExercisePhasesTable,
                    ExercisePhase
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisePhasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisePhasesTable,
      ExercisePhase,
      $$ExercisePhasesTableFilterComposer,
      $$ExercisePhasesTableOrderingComposer,
      $$ExercisePhasesTableAnnotationComposer,
      $$ExercisePhasesTableCreateCompanionBuilder,
      $$ExercisePhasesTableUpdateCompanionBuilder,
      (
        ExercisePhase,
        BaseReferences<_$AppDatabase, $ExercisePhasesTable, ExercisePhase>,
      ),
      ExercisePhase,
      PrefetchHooks Function()
    >;
typedef $$ExerciseSafetyChecksTableCreateCompanionBuilder =
    ExerciseSafetyChecksCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String exerciseId,
      required String description,
      Value<bool> checked,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ExerciseSafetyChecksTableUpdateCompanionBuilder =
    ExerciseSafetyChecksCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> exerciseId,
      Value<String> description,
      Value<bool> checked,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ExerciseSafetyChecksTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseSafetyChecksTable> {
  $$ExerciseSafetyChecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseSafetyChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseSafetyChecksTable> {
  $$ExerciseSafetyChecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseSafetyChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseSafetyChecksTable> {
  $$ExerciseSafetyChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ExerciseSafetyChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseSafetyChecksTable,
          ExerciseSafetyCheck,
          $$ExerciseSafetyChecksTableFilterComposer,
          $$ExerciseSafetyChecksTableOrderingComposer,
          $$ExerciseSafetyChecksTableAnnotationComposer,
          $$ExerciseSafetyChecksTableCreateCompanionBuilder,
          $$ExerciseSafetyChecksTableUpdateCompanionBuilder,
          (
            ExerciseSafetyCheck,
            BaseReferences<
              _$AppDatabase,
              $ExerciseSafetyChecksTable,
              ExerciseSafetyCheck
            >,
          ),
          ExerciseSafetyCheck,
          PrefetchHooks Function()
        > {
  $$ExerciseSafetyChecksTableTableManager(
    _$AppDatabase db,
    $ExerciseSafetyChecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseSafetyChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseSafetyChecksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseSafetyChecksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSafetyChecksCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                description: description,
                checked: checked,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String exerciseId,
                required String description,
                Value<bool> checked = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSafetyChecksCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                description: description,
                checked: checked,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseSafetyChecksTable, ExerciseSafetyCheck>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseSafetyChecksTable,
                    ExerciseSafetyCheck
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseSafetyChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseSafetyChecksTable,
      ExerciseSafetyCheck,
      $$ExerciseSafetyChecksTableFilterComposer,
      $$ExerciseSafetyChecksTableOrderingComposer,
      $$ExerciseSafetyChecksTableAnnotationComposer,
      $$ExerciseSafetyChecksTableCreateCompanionBuilder,
      $$ExerciseSafetyChecksTableUpdateCompanionBuilder,
      (
        ExerciseSafetyCheck,
        BaseReferences<
          _$AppDatabase,
          $ExerciseSafetyChecksTable,
          ExerciseSafetyCheck
        >,
      ),
      ExerciseSafetyCheck,
      PrefetchHooks Function()
    >;
typedef $$ExerciseVehiclesTableCreateCompanionBuilder =
    ExerciseVehiclesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String exerciseId,
      required String vehicleId,
      Value<String?> patternId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ExerciseVehiclesTableUpdateCompanionBuilder =
    ExerciseVehiclesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> exerciseId,
      Value<String> vehicleId,
      Value<String?> patternId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ExerciseVehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseVehiclesTable> {
  $$ExerciseVehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseVehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseVehiclesTable> {
  $$ExerciseVehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseVehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseVehiclesTable> {
  $$ExerciseVehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get patternId =>
      $composableBuilder(column: $table.patternId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ExerciseVehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseVehiclesTable,
          ExerciseVehicle,
          $$ExerciseVehiclesTableFilterComposer,
          $$ExerciseVehiclesTableOrderingComposer,
          $$ExerciseVehiclesTableAnnotationComposer,
          $$ExerciseVehiclesTableCreateCompanionBuilder,
          $$ExerciseVehiclesTableUpdateCompanionBuilder,
          (
            ExerciseVehicle,
            BaseReferences<
              _$AppDatabase,
              $ExerciseVehiclesTable,
              ExerciseVehicle
            >,
          ),
          ExerciseVehicle,
          PrefetchHooks Function()
        > {
  $$ExerciseVehiclesTableTableManager(
    _$AppDatabase db,
    $ExerciseVehiclesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseVehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseVehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseVehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String?> patternId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseVehiclesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                vehicleId: vehicleId,
                patternId: patternId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String exerciseId,
                required String vehicleId,
                Value<String?> patternId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseVehiclesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                vehicleId: vehicleId,
                patternId: patternId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseVehiclesTable, ExerciseVehicle>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseVehiclesTable,
                    ExerciseVehicle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseVehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseVehiclesTable,
      ExerciseVehicle,
      $$ExerciseVehiclesTableFilterComposer,
      $$ExerciseVehiclesTableOrderingComposer,
      $$ExerciseVehiclesTableAnnotationComposer,
      $$ExerciseVehiclesTableCreateCompanionBuilder,
      $$ExerciseVehiclesTableUpdateCompanionBuilder,
      (
        ExerciseVehicle,
        BaseReferences<_$AppDatabase, $ExerciseVehiclesTable, ExerciseVehicle>,
      ),
      ExerciseVehicle,
      PrefetchHooks Function()
    >;
typedef $$ExerciseAssignmentsTableCreateCompanionBuilder =
    ExerciseAssignmentsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String exerciseId,
      required String functionId,
      required String personId,
      Value<int> rowid,
    });
typedef $$ExerciseAssignmentsTableUpdateCompanionBuilder =
    ExerciseAssignmentsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> exerciseId,
      Value<String> functionId,
      Value<String> personId,
      Value<int> rowid,
    });

class $$ExerciseAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseAssignmentsTable> {
  $$ExerciseAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseAssignmentsTable> {
  $$ExerciseAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseAssignmentsTable> {
  $$ExerciseAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get functionId => $composableBuilder(
    column: $table.functionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);
}

class $$ExerciseAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseAssignmentsTable,
          ExerciseAssignment,
          $$ExerciseAssignmentsTableFilterComposer,
          $$ExerciseAssignmentsTableOrderingComposer,
          $$ExerciseAssignmentsTableAnnotationComposer,
          $$ExerciseAssignmentsTableCreateCompanionBuilder,
          $$ExerciseAssignmentsTableUpdateCompanionBuilder,
          (
            ExerciseAssignment,
            BaseReferences<
              _$AppDatabase,
              $ExerciseAssignmentsTable,
              ExerciseAssignment
            >,
          ),
          ExerciseAssignment,
          PrefetchHooks Function()
        > {
  $$ExerciseAssignmentsTableTableManager(
    _$AppDatabase db,
    $ExerciseAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseAssignmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseAssignmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> functionId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAssignmentsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                functionId: functionId,
                personId: personId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String exerciseId,
                required String functionId,
                required String personId,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAssignmentsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                functionId: functionId,
                personId: personId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseAssignmentsTable, ExerciseAssignment>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseAssignmentsTable,
                    ExerciseAssignment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseAssignmentsTable,
      ExerciseAssignment,
      $$ExerciseAssignmentsTableFilterComposer,
      $$ExerciseAssignmentsTableOrderingComposer,
      $$ExerciseAssignmentsTableAnnotationComposer,
      $$ExerciseAssignmentsTableCreateCompanionBuilder,
      $$ExerciseAssignmentsTableUpdateCompanionBuilder,
      (
        ExerciseAssignment,
        BaseReferences<
          _$AppDatabase,
          $ExerciseAssignmentsTable,
          ExerciseAssignment
        >,
      ),
      ExerciseAssignment,
      PrefetchHooks Function()
    >;
typedef $$AlarmPlanEntriesTableCreateCompanionBuilder =
    AlarmPlanEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      required String exerciseId,
      required String label,
      Value<String> kind,
      Value<String?> vehicleId,
      required int alarmOffset,
      Value<int?> departOffset,
      Value<int?> arriveOffset,
      Value<String?> note,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$AlarmPlanEntriesTableUpdateCompanionBuilder =
    AlarmPlanEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> exerciseId,
      Value<String> label,
      Value<String> kind,
      Value<String?> vehicleId,
      Value<int> alarmOffset,
      Value<int?> departOffset,
      Value<int?> arriveOffset,
      Value<String?> note,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$AlarmPlanEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmPlanEntriesTable> {
  $$AlarmPlanEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get alarmOffset => $composableBuilder(
    column: $table.alarmOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get departOffset => $composableBuilder(
    column: $table.departOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get arriveOffset => $composableBuilder(
    column: $table.arriveOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmPlanEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmPlanEntriesTable> {
  $$AlarmPlanEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alarmOffset => $composableBuilder(
    column: $table.alarmOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get departOffset => $composableBuilder(
    column: $table.departOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get arriveOffset => $composableBuilder(
    column: $table.arriveOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmPlanEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmPlanEntriesTable> {
  $$AlarmPlanEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<int> get alarmOffset => $composableBuilder(
    column: $table.alarmOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get departOffset => $composableBuilder(
    column: $table.departOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get arriveOffset => $composableBuilder(
    column: $table.arriveOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AlarmPlanEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmPlanEntriesTable,
          AlarmPlanEntry,
          $$AlarmPlanEntriesTableFilterComposer,
          $$AlarmPlanEntriesTableOrderingComposer,
          $$AlarmPlanEntriesTableAnnotationComposer,
          $$AlarmPlanEntriesTableCreateCompanionBuilder,
          $$AlarmPlanEntriesTableUpdateCompanionBuilder,
          (
            AlarmPlanEntry,
            BaseReferences<
              _$AppDatabase,
              $AlarmPlanEntriesTable,
              AlarmPlanEntry
            >,
          ),
          AlarmPlanEntry,
          PrefetchHooks Function()
        > {
  $$AlarmPlanEntriesTableTableManager(
    _$AppDatabase db,
    $AlarmPlanEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmPlanEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmPlanEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmPlanEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> vehicleId = const Value.absent(),
                Value<int> alarmOffset = const Value.absent(),
                Value<int?> departOffset = const Value.absent(),
                Value<int?> arriveOffset = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmPlanEntriesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                label: label,
                kind: kind,
                vehicleId: vehicleId,
                alarmOffset: alarmOffset,
                departOffset: departOffset,
                arriveOffset: arriveOffset,
                note: note,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String exerciseId,
                required String label,
                Value<String> kind = const Value.absent(),
                Value<String?> vehicleId = const Value.absent(),
                required int alarmOffset,
                Value<int?> departOffset = const Value.absent(),
                Value<int?> arriveOffset = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmPlanEntriesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                exerciseId: exerciseId,
                label: label,
                kind: kind,
                vehicleId: vehicleId,
                alarmOffset: alarmOffset,
                departOffset: departOffset,
                arriveOffset: arriveOffset,
                note: note,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlarmPlanEntriesTable, AlarmPlanEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AlarmPlanEntriesTable,
                    AlarmPlanEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmPlanEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmPlanEntriesTable,
      AlarmPlanEntry,
      $$AlarmPlanEntriesTableFilterComposer,
      $$AlarmPlanEntriesTableOrderingComposer,
      $$AlarmPlanEntriesTableAnnotationComposer,
      $$AlarmPlanEntriesTableCreateCompanionBuilder,
      $$AlarmPlanEntriesTableUpdateCompanionBuilder,
      (
        AlarmPlanEntry,
        BaseReferences<_$AppDatabase, $AlarmPlanEntriesTable, AlarmPlanEntry>,
      ),
      AlarmPlanEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$QualificationsTableTableManager get qualifications =>
      $$QualificationsTableTableManager(_db, _db.qualifications);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$PersonQualificationsTableTableManager get personQualifications =>
      $$PersonQualificationsTableTableManager(_db, _db.personQualifications);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$CrewFunctionsTableTableManager get crewFunctions =>
      $$CrewFunctionsTableTableManager(_db, _db.crewFunctions);
  $$CrewPatternsTableTableManager get crewPatterns =>
      $$CrewPatternsTableTableManager(_db, _db.crewPatterns);
  $$CrewPatternFunctionsTableTableManager get crewPatternFunctions =>
      $$CrewPatternFunctionsTableTableManager(_db, _db.crewPatternFunctions);
  $$KeywordsTableTableManager get keywords =>
      $$KeywordsTableTableManager(_db, _db.keywords);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExercisePhasesTableTableManager get exercisePhases =>
      $$ExercisePhasesTableTableManager(_db, _db.exercisePhases);
  $$ExerciseSafetyChecksTableTableManager get exerciseSafetyChecks =>
      $$ExerciseSafetyChecksTableTableManager(_db, _db.exerciseSafetyChecks);
  $$ExerciseVehiclesTableTableManager get exerciseVehicles =>
      $$ExerciseVehiclesTableTableManager(_db, _db.exerciseVehicles);
  $$ExerciseAssignmentsTableTableManager get exerciseAssignments =>
      $$ExerciseAssignmentsTableTableManager(_db, _db.exerciseAssignments);
  $$AlarmPlanEntriesTableTableManager get alarmPlanEntries =>
      $$AlarmPlanEntriesTableTableManager(_db, _db.alarmPlanEntries);
}
