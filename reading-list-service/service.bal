import ballerina/uuid;
import ballerina/http;

enum Status {
    reading = "reading",
    read = "read",
    to_read = "to_read"
}

type BookItem record {|
    string title;
    string author;
    string status;
|};

type Book record {|
    *BookItem;
    string id;
|};

type RiskResponse record {
boolean hasRisk;
};

type RiskRequest record {
string ip;
};

type ipGeolocationResp record {
string ip;
string country_code2;
};

final string geoApiKey = "3e18b946e2904a5687415e30a5485d76";

map<Book> books = {};

service /readinglist on new http:Listener(9090) {

    resource function get books() returns Book[]|error? {
        return books.toArray();
    }

    resource function post books(@http:Payload BookItem newBook) returns http:Response|error? {
        string bookId = uuid:createType1AsString();
        books[bookId] = {...newBook, id: bookId};
        Book[] bookArray = books.toArray();
        http:Response response = new;
        response.setJsonPayload(bookArray);
        response.statusCode = http:OK.code;
        return response;
    }

    resource function delete books(string id) returns record {|*http:Ok;|}|error? {
        _ = books.remove(id);
        return {};
    }
}


service / on new http:Listener(8090) {
    resource function post risk(@http:Payload RiskRequest req) returns RiskResponse|error? {

         string ip = req.ip;
         http:Client ipGeolocation = check new ("https://api.ipgeolocation.io");
         ipGeolocationResp geoResponse = check ipGeolocation->get(string `/ipgeo?apiKey=${geoApiKey}&ip=${ip}&fields=country_code2`);

         RiskResponse resp = {
              // hasRisk is true if the country code of the IP address is not the specified country code.
              hasRisk: geoResponse.country_code2 != "<Specify a country code of your choice>"
         };
         return resp;
    }
}

