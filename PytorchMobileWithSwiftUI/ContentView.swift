//
//  ContentView.swift
//  PytorchMobileWithSwiftUI
//
//  Created by peterpan on 1/12/20.
//  Copyright © 2020 peterpan. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var showImagePickerView: Bool = false
    @State var image: UIImage? = nil
    @State var text: String? = nil
    var body: some View {
        VStack{
            if image != nil{
                Image(uiImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.vertical, CGFloat(10))
            }
            if text != nil {
                Text(text!)
            }
            Button(action: {
                self.showImagePickerView = true
            }) {
                HStack {
                    Text("Pick Image")
                }
            }.foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(40)
                .padding(10)
                .sheet(isPresented:self.$showImagePickerView){
                    ImagePicker(image: self.$image, text: self.$text)
            }
        }
    }
}
