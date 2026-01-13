# 🌩️ Configuration Cloudinary - TrashPicker

## 🎯 Action requise IMMÉDIATEMENT

Avant de lancer l'application, vous devez configurer vos clés Cloudinary.

---

## 📍 OÙ placer vos clés ?

**Fichier à modifier** : **`lib/config/cloudinary_config.dart`**

```dart
class CloudinaryConfig {
  // 1️⃣ PASTE YOUR CLOUD NAME HERE
  static const String cloudName = 'YOUR_CLOUD_NAME_HERE';  // ← REMPLACER ICI

  // 2️⃣ PASTE YOUR UPLOAD PRESET HERE
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET_HERE';  // ← REMPLACER ICI
}
```

---

## 🔑 COMMENT obtenir ces valeurs ? (2 minutes)

### Étape 1 : Récupérer votre Cloud Name

1. Allez sur : **https://cloudinary.com/console**
2. Connectez-vous (ou créez un compte **GRATUIT**)
3. Sur le Dashboard, vous verrez **"Product Environment Credentials"**
4. Copiez la valeur de **"Cloud name"**
   - Exemple : `dq4l3tzyx`

### Étape 2 : Créer un Upload Preset

1. Dans Cloudinary, cliquez sur **Settings** ⚙️ (en haut à droite)
2. Menu latéral : **Upload**
3. Section **"Upload presets"**
4. Cliquez sur **"Add upload preset"** (bouton bleu)
5. Configuration :
   - **Signing Mode** : Sélectionnez **"Unsigned"** ⚠️ (IMPORTANT!)
   - **Upload preset name** : `trashpicker_preset` (ou votre nom)
   - **Folder** (optionnel) : `trash_reports`
6. Cliquez **Save**

### Étape 3 : Coller les valeurs

Ouvrez **`lib/config/cloudinary_config.dart`** et remplacez :

```dart
// EXEMPLE (à adapter avec VOS valeurs)
static const String cloudName = 'dq4l3tzyx';           // ← Votre cloud name
static const String uploadPreset = 'trashpicker_preset';  // ← Votre preset name
```

---

## ✅ Vérification rapide

Après avoir modifié `cloudinary_config.dart`, vérifiez :

- [ ] Vous avez remplacé `YOUR_CLOUD_NAME_HERE`
- [ ] Vous avez remplacé `YOUR_UPLOAD_PRESET_HERE`
- [ ] Votre preset Cloudinary est en mode **"Unsigned"**
- [ ] Vous avez sauvegardé le fichier

---

## 🚀 Lancer l'application

```bash
flutter run -d chrome
# ou
flutter run  # pour Android/iOS
```

---

## 🧪 Tester l'upload

1. Connectez-vous en tant que **Client**
2. **Activez** une demande de récupération (toggle ON)
3. Cliquez sur **"Ajouter photos"**
4. Sélectionnez une image
5. Vous devriez voir :
   - ✅ Barre de progression
   - ✅ Texte "Upload 1/1..."
   - ✅ Snackbar verte "1 photo(s) ajoutée(s) ✓"
   - ✅ Image affichée

---

## ❌ Problèmes courants

### "Configuration Cloudinary manquante"
- Vérifiez que vous avez bien remplacé les valeurs dans `cloudinary_config.dart`
- Relancez l'application

### Upload échoue avec erreur 401
- Vérifiez que votre Upload Preset est en mode **"Unsigned"**
- Dans Cloudinary : Settings > Upload > Votre preset > Edit > Signing Mode = "Unsigned"

### Image ne s'affiche pas
- Vérifiez les logs dans la console (F12)
- Allez dans Cloudinary Media Library pour vérifier que l'image est bien uploadée

---

## 📚 Documentation complète

- **Guide rapide (5 min)** : [CLOUDINARY_QUICK_START.md](CLOUDINARY_QUICK_START.md)
- **Guide complet avec screenshots** : [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md)
- **Notes de migration** : [MIGRATION_CLOUDINARY.md](MIGRATION_CLOUDINARY.md)

---

## 💡 Pourquoi Cloudinary ?

✅ **Fonctionne sur TOUTES les plateformes** (Web, Android, iOS)
✅ **Plan gratuit généreux** : 25 GB stockage + 25 GB bandwidth/mois
✅ **Optimisation automatique** : Compression, WebP, redimensionnement
✅ **CDN ultra-rapide** : Images chargées rapidement partout dans le monde
✅ **Simple** : Seulement 2 clés à configurer

Firebase Storage causait des problèmes sur web (`dart:io` incompatible).

---

## 🎯 Résumé - C'est simple !

1. **Allez sur** [cloudinary.com/console](https://cloudinary.com/console)
2. **Copiez** votre Cloud Name
3. **Créez** un Upload Preset (mode "Unsigned")
4. **Collez** les 2 valeurs dans `lib/config/cloudinary_config.dart`
5. **Lancez** l'app : `flutter run`

**C'est tout !** 🎉

---

**Besoin d'aide ?** Consultez [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md) section "Dépannage"
