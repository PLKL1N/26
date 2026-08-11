function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.startsWith('/images/')) {
        request.uri = uri.replace('/images/', '/');
    } else if (uri === '/images') {
        request.uri = '/';
    }

    return request;
}