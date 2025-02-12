enum ImageType { jpeg, png, gif, webp, bmp, unknown }

extension ImageTypeExtension on ImageType {
  String get extension {
    switch (this) {
      case ImageType.jpeg:
        return '.jpg';
      case ImageType.png:
        return '.png';
      case ImageType.gif:
        return '.gif';
      case ImageType.webp:
        return '.webp';
      case ImageType.bmp:
        return '.bmp';
      case ImageType.unknown:
        return '';
    }
  }
}

ImageType getImageType(List<int> bytes) {
  if (bytes.length < 4) return ImageType.unknown;

  // JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return ImageType.jpeg;
  }

  // PNG: 89 50 4E 47
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return ImageType.png;
  }

  // GIF: 47 49 46 38
  if (bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return ImageType.gif;
  }

  // WebP: 52 49 46 46 ... 57 45 42 50
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return ImageType.webp;
  }

  // BMP: 42 4D
  if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return ImageType.bmp;
  }

  return ImageType.unknown;
}
