import SwiftUI
import ContactsUI
import SwiftData

struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onSelect: ((CNContact) -> Void)? = nil

    func makeUIViewController(context: Context) -> cnContactPickerViewControllerType {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        return picker
    }

    func updateUIViewController(_ uiViewController: cnContactPickerViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if let onSelect = parent.onSelect {
                onSelect(contact)
            } else {
                // Default handling if no closure provided: Create a LockedContact
                let displayName = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown Contact"
                let newLockedContact = LockedContact(contactID: contact.identifier, displayName: displayName)
                parent.modelContext.insert(newLockedContact)
                try? parent.modelContext.save()
            }
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

// Helper to make the code compile without complaints if conditionally compiling
typealias cnContactPickerViewControllerType = CNContactPickerViewController
