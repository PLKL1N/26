function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // "/images/xxx.jpg" -> "/xxx.jpg" (S3 버킷 루트에 저장된 오브젝트 키와 매칭)
    if (uri.startsWith('/images/')) {
        request.uri = uri.substring('/images'.length);
    } else if (uri === '/images') {
        request.uri = '/';
    }

    return request;
}
