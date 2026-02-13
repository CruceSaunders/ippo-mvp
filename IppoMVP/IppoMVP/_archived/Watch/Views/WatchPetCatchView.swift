import SwiftUI

struct WatchPetCatchView: View {
    let petId: String
    let onDismiss: () -> Void
    
    private var pet: GamePetDefinitionWatch? {
        GameDataWatch.shared.pet(byId: petId)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Celebration
            Text("✨ NEW PET! ✨")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cyan)
            
            Spacer()
            
            // Pet
            if let pet = pet {
                Text(pet.emoji)
                    .font(.system(size: 60))
                
                Text(pet.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("(Baby)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Message
            Text("See on iPhone!")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Continue button
            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

#Preview {
    WatchPetCatchView(petId: "pet_01") {}
}
