import SwiftUI
import P5CommandLabCore

struct CustomRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var summary = ""
    @State private var transport: RecipeTransport = .rest
    @State private var method = "GET"
    @State private var template = ""
    @State private var fieldsText = ""
    let onSave: (CommandRecipe) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Custom Recipe").font(.title2.bold())
            TextField("Recipe name", text: $name)
            TextField("What this demonstrates", text: $summary)
            Picker("Transport", selection: $transport) {
                ForEach(RecipeTransport.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            if transport == .rest {
                Picker("HTTP method", selection: $method) {
                    ForEach(["GET", "POST", "PUT", "DELETE"], id: \.self, content: Text.init)
                }
            }
            Text(transport == .rest ? "Relative REST path" : "Arguments after nsdchat -c")
                .font(.caption.bold())
            TextField(transport == .rest ? "general/jobs" : "Volume {volume} barcode", text: $template)
                .font(.system(.body, design: .monospaced))
            Text("Variables (comma-separated names)").font(.caption.bold())
            TextField("volume, client, path", text: $fieldsText)
            Text("Use variables as {name} in the template. Custom REST recipes send Basic authentication and Accept: application/json. Mutating methods are available for teaching, but inspect the preview carefully before running them.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let keys = fieldsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    let recipe = CommandRecipe(
                        name: name,
                        summary: summary,
                        transport: transport,
                        method: method,
                        template: template,
                        fields: keys.map { RecipeField($0, label: $0.capitalized) }
                    )
                    onSave(recipe)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || template.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding(22)
        .frame(width: 590)
    }
}
