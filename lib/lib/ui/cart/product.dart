class ProductDetails {
  final String variety;
  final String origin;
  final String nutrition;
  final String benefits;
  final String storage;
  final String usage;
  final String qualityLabel;
  final String rating;

  ProductDetails({
    required this.variety,
    required this.origin,
    required this.nutrition,
    required this.benefits,
    required this.storage,
    required this.usage,
    required this.qualityLabel,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'variety': variety,
      'origin': origin,
      'nutrition': nutrition,
      'benefits': benefits,
      'storage': storage,
      'usage': usage,
      'qualityLabel': qualityLabel,
      'rating': rating,
    };
  }

  factory ProductDetails.fromMap(Map<String, dynamic> map) {
    return ProductDetails(
      variety: map['variety'] ?? '',
      origin: map['origin'] ?? '',
      nutrition: map['nutrition'] ?? '',
      benefits: map['benefits'] ?? '',
      storage: map['storage'] ?? '',
      usage: map['usage'] ?? '',
      qualityLabel: map['qualityLabel'] ?? '',
      rating: map['rating'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final int weight;
  final Map<String, ProductDetails> translations;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.weight,
    required this.translations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'weight': weight,
      'translations': translations.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final translationsMap = map['translations'] as Map<String, dynamic>? ?? {};

    double parsedPrice = 0.0;
    if (map['price'] is num) {
      parsedPrice = (map['price'] as num).toDouble();
    } else if (map['price'] is String) {
      parsedPrice = double.tryParse(map['price']) ?? 0.0;
    }

    int parsedWeight = 0;
    if (map['weight'] is num) {
      parsedWeight = (map['weight'] as num).toInt();
    } else if (map['weight'] is String) {
      parsedWeight = int.tryParse(map['weight']) ?? 0;
    }

    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      price: parsedPrice,
      weight: parsedWeight,
      translations: translationsMap.map(
        (k, v) =>
            MapEntry(k, ProductDetails.fromMap(v as Map<String, dynamic>)),
      ),
    );
  }
}

// HELPER: Map YOLO tags to your Product IDs
final Map<String, String> yoloToIdMap = {
  "fresh tomato": "108903",
  "fresh beans": "108912",
  "fresh red bird eye chili": "108914",
  "fresh eggplant": "108920",
  "fresh oranges": "108943",
  "fresh red apple": "108908",
  "fresh lemon": "111332",
};
final Map<String, String> manualProductDatabase = {
  "108913": "Japanese Cucumber ",
  "111670": "CILI PADI SIAM",
  "108914": "CILI PADI MERAH",
  "110753": "SAWI PENDEK",
  "108903": "TOMATO",
  "108912": "BEANS",
  "110752": "CABBAGE",
  "120139": "BABY ROMAINE",
  "111332": "LEMON",
  "108943": "ORANGE",
  "108908": "RED APPLE",
  "108920": "TERUNG",
  "111673": "HALIA TUA",
};

final Map<String, Product> productDatabase = {
  "108913": Product(
    id: "108913",
    name: "JAPANESE CUCUMBER",
    price: 3.00,
    weight: 350,
    translations: {
      'en': ProductDetails(
        variety: "Japanese Cucumber",
        origin: "Malaysia",
        nutrition: "16 kcal, High water content",
        benefits: "Hydrating and good for skin health.",
        storage: "Store in refrigerator.",
        usage: "Salads, sushi, fresh snacks.",
        qualityLabel: "Fresh Farm",
        rating: "4.6/5",
      ),
      'ms': ProductDetails(
        variety: "Timun Jepun",
        origin: "Malaysia",
        nutrition: "16 kcal, Tinggi kandungan air",
        benefits: "Menghidratkan badan.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Salad dan sushi.",
        qualityLabel: "Segar",
        rating: "4.6/5",
      ),
      'zh': ProductDetails(
        variety: "日本黄瓜",
        origin: "马来西亚",
        nutrition: "16千卡，高含水量",
        benefits: "补水和美容。",
        storage: "冷藏保存。",
        usage: "沙拉和寿司。",
        qualityLabel: "新鲜农场",
        rating: "4.6/5",
      ),
      'ta': ProductDetails(
        variety: "ஜப்பானீஸ் வெள்ளரி",
        origin: "மலேசியா",
        nutrition: "16 கலோரி",
        benefits: "உடலை ஈரப்பதமாக வைத்திருக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "சாலட்.",
        qualityLabel: "புதியது",
        rating: "4.6/5",
      ),
    },
  ),

  "111670": Product(
    id: "111670",
    name: "CILI PADI SIAM",
    price: 2.50,
    weight: 130,
    translations: {
      'en': ProductDetails(
        variety: "Bird's Eye Chili",
        origin: "Thailand",
        nutrition: "40 kcal, Rich in Vitamin C",
        benefits: "Boosts metabolism.",
        storage: "Keep refrigerated.",
        usage: "Cooking, spicy sauces.",
        qualityLabel: "Premium",
        rating: "4.5/5",
      ),
      'ms': ProductDetails(
        variety: "Cili Padi Siam",
        origin: "Thailand",
        nutrition: "40 kcal",
        benefits: "Meningkatkan metabolisme.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Masakan pedas.",
        qualityLabel: "Premium",
        rating: "4.5/5",
      ),
      'zh': ProductDetails(
        variety: "泰国小米辣",
        origin: "泰国",
        nutrition: "40千卡",
        benefits: "促进新陈代谢。",
        storage: "冷藏保存。",
        usage: "烹饪辣菜。",
        qualityLabel: "优质",
        rating: "4.5/5",
      ),
      'ta': ProductDetails(
        variety: "சிறிய மிளகாய்",
        origin: "தாய்லாந்து",
        nutrition: "40 கலோரி",
        benefits: "மெட்டபாலிசத்தை அதிகரிக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "கார உணவு.",
        qualityLabel: "பிரீமியம்",
        rating: "4.5/5",
      ),
    },
  ),
  "108914": Product(
    id: "108914",
    name: "CILI PADI MERAH",
    price: 4.50,
    weight: 1,
    translations: {
      'en': ProductDetails(
        variety: "Red Bird's Eye Chili",
        origin: "Malaysia",
        nutrition: "40 kcal, Rich in antioxidants",
        benefits: "Improves circulation and boosts metabolism.",
        storage: "Refrigerate to keep fresh longer.",
        usage: "Used in spicy dishes and sambal.",
        qualityLabel: "Fresh Farm",
        rating: "4.7/5",
      ),
      'ms': ProductDetails(
        variety: "Cili Padi Merah",
        origin: "Malaysia",
        nutrition: "40 kcal, Kaya antioksidan",
        benefits: "Meningkatkan peredaran darah.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Digunakan dalam masakan pedas dan sambal.",
        qualityLabel: "Segar",
        rating: "4.7/5",
      ),
      'zh': ProductDetails(
        variety: "红小米辣",
        origin: "马来西亚",
        nutrition: "40千卡，富含抗氧化剂",
        benefits: "促进血液循环。",
        storage: "冷藏保存。",
        usage: "用于辣味菜肴。",
        qualityLabel: "新鲜农场",
        rating: "4.7/5",
      ),
      'ta': ProductDetails(
        variety: "சிவப்பு கார மிளகாய்",
        origin: "மலேசியா",
        nutrition: "40 கலோரி",
        benefits: "இரத்த ஓட்டத்தை மேம்படுத்தும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "கார உணவுகளில் பயன்படுத்தப்படுகிறது.",
        qualityLabel: "புதியது",
        rating: "4.7/5",
      ),
    },
  ),

  "110753": Product(
    id: "110753",
    name: "SAWI PENDEK",
    price: 2.00,
    weight: 250,
    translations: {
      'en': ProductDetails(
        variety: "Short Mustard Greens",
        origin: "Malaysia",
        nutrition: "27 kcal, High Vitamin A and C",
        benefits: "Supports immune system and eye health.",
        storage: "Store in refrigerator vegetable drawer.",
        usage: "Used in soups, stir-fry, and noodles.",
        qualityLabel: "Farm Fresh",
        rating: "4.5/5",
      ),
      'ms': ProductDetails(
        variety: "Sawi Pendek",
        origin: "Malaysia",
        nutrition: "27 kcal, Tinggi Vitamin A dan C",
        benefits: "Baik untuk sistem imun.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Digunakan dalam sup dan masakan tumis.",
        qualityLabel: "Segar",
        rating: "4.5/5",
      ),
      'zh': ProductDetails(
        variety: "短芥菜",
        origin: "马来西亚",
        nutrition: "27千卡，富含维生素A和C",
        benefits: "增强免疫系统。",
        storage: "冷藏保存。",
        usage: "用于汤和炒菜。",
        qualityLabel: "农场新鲜",
        rating: "4.5/5",
      ),
      'ta': ProductDetails(
        variety: "சாவி கீரை",
        origin: "மலேசியா",
        nutrition: "27 கலோரி",
        benefits: "உடல் நோய் எதிர்ப்பு சக்தி அதிகரிக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "சூப் மற்றும் வறுவல் உணவு.",
        qualityLabel: "புதியது",
        rating: "4.5/5",
      ),
    },
  ),

  "108903": Product(
    id: "108903",
    name: "TOMATO",
    price: 3.00,
    weight: 400,
    translations: {
      'en': ProductDetails(
        variety: "Red Tomato",
        origin: "Malaysia",
        nutrition: "18 kcal, Rich in Lycopene",
        benefits: "Good for heart health.",
        storage: "Room temperature or refrigerate.",
        usage: "Salads, cooking, sauces.",
        qualityLabel: "Farm Fresh",
        rating: "4.7/5",
      ),
      'ms': ProductDetails(
        variety: "Tomato Merah",
        origin: "Malaysia",
        nutrition: "18 kcal",
        benefits: "Baik untuk jantung.",
        storage: "Simpan pada suhu bilik.",
        usage: "Salad dan masakan.",
        qualityLabel: "Segar",
        rating: "4.7/5",
      ),
      'zh': ProductDetails(
        variety: "番茄",
        origin: "马来西亚",
        nutrition: "18千卡",
        benefits: "有益心脏健康。",
        storage: "室温或冷藏。",
        usage: "沙拉和烹饪。",
        qualityLabel: "农场新鲜",
        rating: "4.7/5",
      ),
      'ta': ProductDetails(
        variety: "தக்காளி",
        origin: "மலேசியா",
        nutrition: "18 கலோரி",
        benefits: "இதயத்திற்கு நல்லது.",
        storage: "அறை வெப்பநிலையில் வைக்கவும்.",
        usage: "சாலட் மற்றும் சமையல்.",
        qualityLabel: "புதியது",
        rating: "4.7/5",
      ),
    },
  ),

  "108912": Product(
    id: "108912",
    name: "BEANS",
    price: 4.20,
    weight: 250,
    translations: {
      'en': ProductDetails(
        variety: "Green Beans",
        origin: "Malaysia",
        nutrition: "31 kcal, High fiber",
        benefits: "Supports digestion.",
        storage: "Refrigerate in vegetable drawer.",
        usage: "Stir fry, salads.",
        qualityLabel: "Organic",
        rating: "4.6/5",
      ),
      'ms': ProductDetails(
        variety: "Kacang Buncis",
        origin: "Malaysia",
        nutrition: "31 kcal",
        benefits: "Baik untuk pencernaan.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Tumis dan salad.",
        qualityLabel: "Organik",
        rating: "4.6/5",
      ),
      'zh': ProductDetails(
        variety: "四季豆",
        origin: "马来西亚",
        nutrition: "31千卡",
        benefits: "帮助消化。",
        storage: "冷藏。",
        usage: "炒菜和沙拉。",
        qualityLabel: "有机",
        rating: "4.6/5",
      ),
      'ta': ProductDetails(
        variety: "பீன்ஸ்",
        origin: "மலேசியா",
        nutrition: "31 கலோரி",
        benefits: "செரிமானத்திற்கு நல்லது.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "தோசை மற்றும் சாலட்.",
        qualityLabel: "ஆர்கானிக்",
        rating: "4.6/5",
      ),
    },
  ),
  "110752": Product(
    id: "110752",
    name: "CABBAGE",
    price: 2.0,
    weight: 550,
    translations: {
      'en': ProductDetails(
        variety: "Green Cabbage",
        origin: "Malaysia",
        nutrition: "25 kcal, High Vitamin C and fiber",
        benefits: "Supports digestion and strengthens immunity.",
        storage: "Store in refrigerator to maintain freshness.",
        usage: "Used in salads, stir-fry, soups, and coleslaw.",
        qualityLabel: "Farm Fresh",
        rating: "4.6/5",
      ),
      'ms': ProductDetails(
        variety: "Kubis Hijau",
        origin: "Malaysia",
        nutrition: "25 kcal, Tinggi Vitamin C",
        benefits: "Baik untuk penghadaman dan imuniti.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Digunakan dalam salad dan masakan tumis.",
        qualityLabel: "Segar",
        rating: "4.6/5",
      ),
      'zh': ProductDetails(
        variety: "卷心菜",
        origin: "马来西亚",
        nutrition: "25千卡，富含维生素C",
        benefits: "帮助消化并增强免疫力。",
        storage: "冷藏保存。",
        usage: "沙拉、炒菜和汤。",
        qualityLabel: "农场新鲜",
        rating: "4.6/5",
      ),
      'ta': ProductDetails(
        variety: "கோஸ் கீரை",
        origin: "மலேசியா",
        nutrition: "25 கலோரி",
        benefits: "செரிமானத்திற்கு உதவுகிறது.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "சாலட் மற்றும் வறுவல் உணவு.",
        qualityLabel: "புதியது",
        rating: "4.6/5",
      ),
    },
  ),

  "120139": Product(
    id: "120139",
    name: "BABY ROMAINE",
    price: 2.00,
    weight: 250,
    translations: {
      'en': ProductDetails(
        variety: "Baby Romaine Lettuce",
        origin: "Malaysia",
        nutrition: "17 kcal, Rich in Vitamin A",
        benefits: "Supports eye health and hydration.",
        storage: "Store in refrigerator vegetable compartment.",
        usage: "Used in salads, wraps, and sandwiches.",
        qualityLabel: "Organic",
        rating: "4.7/5",
      ),
      'ms': ProductDetails(
        variety: "Salad Romaine Bayi",
        origin: "Malaysia",
        nutrition: "17 kcal, Kaya Vitamin A",
        benefits: "Baik untuk kesihatan mata.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Digunakan dalam salad dan sandwic.",
        qualityLabel: "Organik",
        rating: "4.7/5",
      ),
      'zh': ProductDetails(
        variety: "迷你罗马生菜",
        origin: "马来西亚",
        nutrition: "17千卡，富含维生素A",
        benefits: "有助于眼睛健康。",
        storage: "冷藏保存。",
        usage: "沙拉和三明治。",
        qualityLabel: "有机",
        rating: "4.7/5",
      ),
      'ta': ProductDetails(
        variety: "ரோமைன் லெட்டூஸ்",
        origin: "மலேசியா",
        nutrition: "17 கலோரி",
        benefits: "கண் ஆரோக்கியத்திற்கு நல்லது.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "சாலட் மற்றும் சாண்ட்விச்.",
        qualityLabel: "ஆர்கானிக்",
        rating: "4.7/5",
      ),
    },
  ),

  "111332": Product(
    id: "111332",
    name: "LEMON",
    price: 4.50,
    weight: 2,
    translations: {
      'en': ProductDetails(
        variety: "Yellow Lemon",
        origin: "Australia",
        nutrition: "29 kcal, High Vitamin C",
        benefits: "Boosts immunity and improves digestion.",
        storage: "Store in refrigerator for longer freshness.",
        usage: "Used in drinks, cooking, and desserts.",
        qualityLabel: "Premium",
        rating: "4.8/5",
      ),
      'ms': ProductDetails(
        variety: "Lemon Kuning",
        origin: "Australia",
        nutrition: "29 kcal, Tinggi Vitamin C",
        benefits: "Meningkatkan imuniti dan penghadaman.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Digunakan dalam minuman dan masakan.",
        qualityLabel: "Premium",
        rating: "4.8/5",
      ),
      'zh': ProductDetails(
        variety: "柠檬",
        origin: "澳大利亚",
        nutrition: "29千卡，富含维生素C",
        benefits: "增强免疫力并促进消化。",
        storage: "冷藏保存。",
        usage: "饮料、烹饪和甜点。",
        qualityLabel: "优质",
        rating: "4.8/5",
      ),
      'ta': ProductDetails(
        variety: "எலுமிச்சை",
        origin: "ஆஸ்திரேலியா",
        nutrition: "29 கலோரி",
        benefits: "நோய் எதிர்ப்பு சக்தி அதிகரிக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "பானங்கள் மற்றும் சமையல்.",
        qualityLabel: "பிரீமியம்",
        rating: "4.8/5",
      ),
    },
  ),

  "108943": Product(
    id: "108943",
    name: "ORANGE",
    price: 4.90,
    weight: 4,
    translations: {
      'en': ProductDetails(
        variety: "Navel Orange",
        origin: "Australia",
        nutrition: "47 kcal, Vitamin C rich",
        benefits: "Boosts immunity.",
        storage: "Store in refrigerator.",
        usage: "Juice or fresh fruit.",
        qualityLabel: "Premium",
        rating: "4.8/5",
      ),
      'ms': ProductDetails(
        variety: "Oren",
        origin: "Australia",
        nutrition: "47 kcal",
        benefits: "Meningkatkan imuniti.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Jus dan snek.",
        qualityLabel: "Premium",
        rating: "4.8/5",
      ),
      'zh': ProductDetails(
        variety: "橙子",
        origin: "澳大利亚",
        nutrition: "47千卡",
        benefits: "增强免疫力。",
        storage: "冷藏。",
        usage: "果汁或直接食用。",
        qualityLabel: "优质",
        rating: "4.8/5",
      ),
      'ta': ProductDetails(
        variety: "ஆரஞ்சு",
        origin: "ஆஸ்திரேலியா",
        nutrition: "47 கலோரி",
        benefits: "நோய் எதிர்ப்பு சக்தி அதிகரிக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "ஜூஸ் அல்லது சாப்பிட.",
        qualityLabel: "பிரீமியம்",
        rating: "4.8/5",
      ),
    },
  ),

  "108908": Product(
    id: "108908",
    name: "RED APPLE",
    price: 4.90,
    weight: 4,
    translations: {
      'en': ProductDetails(
        variety: "Fuji Red Apple",
        origin: "New Zealand",
        nutrition: "52 kcal, High Fiber",
        benefits: "Improves digestion and heart health.",
        storage: "Refrigerate for crispness.",
        usage: "Snacks, juice, or salads.",
        qualityLabel: "Organic",
        rating: "4.8/5",
      ),
      'ms': ProductDetails(
        variety: "Epal Merah Fuji",
        origin: "New Zealand",
        nutrition: "52 kcal",
        benefits: "Meningkatkan penghadaman.",
        storage: "Simpan dalam peti sejuk.",
        usage: "Snek dan jus.",
        qualityLabel: "Organik",
        rating: "4.8/5",
      ),
      'zh': ProductDetails(
        variety: "红富士苹果",
        origin: "新西兰",
        nutrition: "52千卡",
        benefits: "改善消化。",
        storage: "冷藏。",
        usage: "零食或果汁。",
        qualityLabel: "有机认证",
        rating: "4.8/5",
      ),
      'ta': ProductDetails(
        variety: "சிவப்பு ஆப்பிள்",
        origin: "நியூசிலாந்து",
        nutrition: "52 கலோரி",
        benefits: "செரிமானத்திற்கு நல்லது.",
        storage: "குளிர்சாதன பெட்டியில் வைக்கவும்.",
        usage: "ஸ்நாக்ஸ்.",
        qualityLabel: "ஆர்கானிக்",
        rating: "4.8/5",
      ),
    },
  ),

  "108920": Product(
    id: "108920",
    name: "TERUNG",
    price: 3.50,
    weight: 350,
    translations: {
      'en': ProductDetails(
        variety: "Purple Eggplant",
        origin: "Malaysia",
        nutrition: "25 kcal, High fiber and antioxidants",
        benefits: "Supports heart health and digestion.",
        storage: "Store in a cool dry place or refrigerate.",
        usage: "Used in curries, stir-fry, grilled dishes, and stews.",
        qualityLabel: "Farm Fresh",
        rating: "4.5/5",
      ),
      'ms': ProductDetails(
        variety: "Terung Ungu",
        origin: "Malaysia",
        nutrition: "25 kcal, Tinggi serat",
        benefits: "Baik untuk kesihatan jantung dan penghadaman.",
        storage: "Simpan di tempat sejuk atau dalam peti sejuk.",
        usage: "Digunakan dalam kari dan masakan tumis.",
        qualityLabel: "Segar",
        rating: "4.5/5",
      ),
      'zh': ProductDetails(
        variety: "紫茄子",
        origin: "马来西亚",
        nutrition: "25千卡，富含纤维",
        benefits: "有助于心脏健康和消化。",
        storage: "存放在阴凉处或冷藏。",
        usage: "用于咖喱、炒菜和炖菜。",
        qualityLabel: "农场新鲜",
        rating: "4.5/5",
      ),
      'ta': ProductDetails(
        variety: "கத்திரிக்காய்",
        origin: "மலேசியா",
        nutrition: "25 கலோரி",
        benefits: "இதய ஆரோக்கியத்திற்கு நல்லது.",
        storage: "குளிர்ந்த இடத்தில் அல்லது ஃப்ரிட்ஜில் வைக்கவும்.",
        usage: "கறி மற்றும் வறுவல் உணவு.",
        qualityLabel: "புதியது",
        rating: "4.5/5",
      ),
    },
  ),

  "111673": Product(
    id: "111673",
    name: "HALIA TUA",
    price: 2.50,
    weight: 250,
    translations: {
      'en': ProductDetails(
        variety: "Mature Ginger Root",
        origin: "Malaysia",
        nutrition: "80 kcal, Rich in gingerol",
        benefits: "Reduces inflammation and improves digestion.",
        storage: "Store in refrigerator or dry place.",
        usage: "Used in tea, soups, curries, and traditional medicine.",
        qualityLabel: "Premium",
        rating: "4.7/5",
      ),
      'ms': ProductDetails(
        variety: "Halia Tua",
        origin: "Malaysia",
        nutrition: "80 kcal, Kaya gingerol",
        benefits: "Mengurangkan keradangan dan membantu penghadaman.",
        storage: "Simpan dalam peti sejuk atau tempat kering.",
        usage: "Digunakan dalam teh, sup, dan masakan.",
        qualityLabel: "Premium",
        rating: "4.7/5",
      ),
      'zh': ProductDetails(
        variety: "老姜",
        origin: "马来西亚",
        nutrition: "80千卡，富含姜辣素",
        benefits: "减少炎症并促进消化。",
        storage: "冷藏或存放在干燥处。",
        usage: "用于茶、汤和烹饪。",
        qualityLabel: "优质",
        rating: "4.7/5",
      ),
      'ta': ProductDetails(
        variety: "முதிர்ந்த இஞ்சி",
        origin: "மலேசியா",
        nutrition: "80 கலோரி",
        benefits: "செரிமானத்திற்கு உதவுகிறது மற்றும் அழற்சியை குறைக்கும்.",
        storage: "குளிர்சாதன பெட்டியில் அல்லது உலர்ந்த இடத்தில் வைக்கவும்.",
        usage: "தேநீர், சூப் மற்றும் சமையல்.",
        qualityLabel: "பிரீமியம்",
        rating: "4.7/5",
      ),
    },
  ),
};
