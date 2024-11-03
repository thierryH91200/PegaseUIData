import SwiftUI

struct ContentView400: View {
    @State private var name: String = "Doe"
    @State private var surname: String = "John"
    @State private var address: String = ""
    @State private var complement: String = ""
    @State private var postalCode: String = "0"
    @State private var town: String = ""
    @State private var country: String = ""
    @State private var phone: String = ""
    @State private var mobile: String = ""
    @State private var email: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identité")
                .font(.title)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Spacer()
                    Text("Surname")
                        .frame(width: 100, alignment: .leading)
                    TextField("Surname", text: $surname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("Address")
                        .frame(width: 100, alignment: .leading)
                    TextField("Address", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("Complement")
                        .frame(width: 100, alignment: .leading)
                    TextField("Complement", text: $complement)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("CP")
                        .frame(width: 100, alignment: .leading)
                    TextField("Postal Code", text: $postalCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Spacer()
                    Text("Town")
                        .frame(width: 100, alignment: .leading)
                    TextField("Town", text: $town)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("Country")
                        .frame(width: 100, alignment: .leading)
                    TextField("Country", text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("Phone")
                        .frame(width: 100, alignment: .leading)
                    TextField("Phone", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                    Spacer()
                    Text("Mobile")
                        .frame(width: 100, alignment: .leading)
                    TextField("Mobile", text: $mobile)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }

                HStack {
                    Text("Email")
                        .frame(width: 100, alignment: .leading)
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .frame(width: 600)
    }
}

