# 🌩️ Configuration Cloudinary - Guide Complet

Ce guide explique comment configurer Cloudinary pour l'upload d'images dans TrashPicker.

---

## 📋 Table des matières

1. [Pourquoi Cloudinary ?](#pourquoi-cloudinary-)
2. [Création du compte Cloudinary](#création-du-compte-cloudinary)
3. [Configuration des clés API](#configuration-des-clés-api)
4. [Création de l'Upload Preset](#création-de-lupload-preset)
5. [Test de la configuration](#test-de-la-configuration)
6. [Dépannage](#dépannage)

---

## ✨ Pourquoi Cloudinary ?

Cloudinary a été choisi pour remplacer Firebase Storage car :

- ✅ **Fonctionne sur toutes les plateformes** : Web, Android, iOS sans code spécifique
- ✅ **Upload direct depuis le client** : Pas besoin de serveur intermédiaire
- ✅ **Optimisation automatique** : Compression, format adaptatif (WebP), redimensionnement
- ✅ **CDN ultra-rapide** : Delivery rapide dans le monde entier
- ✅ **Généreux plan gratuit** : 25 GB de stockage + 25 GB de bande passante/mois
- ✅ **Simple à configurer** : 2 clés suffisent (cloud name + upload preset)

---

## 🆕 Création du compte Cloudinary

### Étape 1 : S'inscrire

1. Allez sur [https://cloudinary.com/users/register_free](https://cloudinary.com/users/register_free)
2. Remplissez le formulaire d'inscription :
   - Nom
   - Email
   - Mot de passe
   - Choisissez "Developer" comme rôle
3. Validez votre email
4. Connectez-vous à [https://console.cloudinary.com](https://console.cloudinary.com)

### Étape 2 : Récupérer votre Cloud Name

Une fois connecté au Dashboard :

1. Vous verrez une section **"Product Environment Credentials"** en haut
2. Copiez la valeur de **"Cloud name"**
   - Exemple : `dq4l3tzyx` (c'est un identifiant unique généré par Cloudinary)

📝 **Notez cette valeur**, vous en aurez besoin à l'étape 3.

---

## 🔑 Configuration des clés API

### Étape 3 : Ajouter le Cloud Name dans le projet

1. Ouvrez le fichier : **`lib/config/cloudinary_config.dart`**

2. Remplacez la ligne 18 :
   ```dart
   // AVANT
   static const String cloudName = 'YOUR_CLOUD_NAME_HERE';

   // APRÈS (exemple avec votre cloud name)
   static const String cloudName = 'dq4l3tzyx';
   ```

3. **Sauvegardez le fichier**

---

## 📤 Création de l'Upload Preset

Les Upload Presets permettent d'uploader des images **sans authentification serveur** (upload non signé).

### Étape 4 : Créer un Upload Preset

1. Allez dans **Settings** (icône engrenage en haut à droite)
2. Cliquez sur l'onglet **"Upload"** dans la barre latérale
3. Scrollez jusqu'à la section **"Upload presets"**
4. Cliquez sur **"Add upload preset"** (bouton bleu en haut à droite)

### Étape 5 : Configurer le Preset

Dans le formulaire qui apparaît :

#### 🔓 Signing Mode
- **Sélectionnez : "Unsigned"**
  - ⚠️ C'est CRUCIAL ! Sans cela, l'upload depuis le client ne fonctionnera pas

#### 📁 Upload preset name
- **Entrez : `trashpicker_preset`** (ou le nom de votre choix)
  - Exemple : `trashpicker_preset`, `trash_uploads`, `mobile_uploads`

#### 📂 Folder (optionnel mais recommandé)
- **Entrez : `trash_reports`**
  - Cela organisera vos images dans un dossier Cloudinary
  - Les images seront automatiquement dans : `trash_reports/report_id/image.jpg`

#### 🎨 Autres options (optionnelles)
Vous pouvez laisser les valeurs par défaut ou configurer :
- **Allowed formats** : `jpg, png, webp, heic` (formats autorisés)
- **Max file size** : `10485760` (10 MB max par image)
- **Quality** : `auto:good` (compression automatique)
- **Format** : `auto` (conversion automatique en WebP si le navigateur supporte)

#### 💾 Sauvegarder
- Cliquez sur **"Save"** en bas du formulaire
- Votre preset apparaîtra dans la liste

### Étape 6 : Ajouter l'Upload Preset dans le projet

1. Copiez le nom du preset que vous venez de créer (exemple : `trashpicker_preset`)

2. Ouvrez le fichier : **`lib/config/cloudinary_config.dart`**

3. Remplacez la ligne 33 :
   ```dart
   // AVANT
   static const String uploadPreset = 'YOUR_UPLOAD_PRESET_HERE';

   // APRÈS (avec le nom de votre preset)
   static const String uploadPreset = 'trashpicker_preset';
   ```

4. **Sauvegardez le fichier**

---

## ✅ Fichier de configuration final

Votre fichier `lib/config/cloudinary_config.dart` devrait ressembler à :

```dart
class CloudinaryConfig {
  static const String cloudName = 'dq4l3tzyx';  // ← Votre cloud name
  static const String uploadPreset = 'trashpicker_preset';  // ← Votre preset
  static const String uploadFolder = 'trash_reports';  // Optionnel

  // ... reste du code
}
```

---

## 🧪 Test de la configuration

### Étape 7 : Tester l'upload

1. **Lancez l'application** :
   ```bash
   flutter run -d chrome
   # ou
   flutter run  # pour Android/iOS
   ```

2. **Connectez-vous en tant que client**

3. **Activez une demande de récupération** (toggle ON)

4. **Cliquez sur "Ajouter photos"**

5. **Sélectionnez une image**

6. **Vérifiez dans la console DevTools** (F12) :
   ```
   ✅ CloudinaryService initialisé avec cloud: dq4l3tzyx
   🔄 Upload Cloudinary - Fichier: image.jpg
   📖 Lecture des bytes depuis XFile...
   📦 Taille du fichier: 234567 bytes
   ⏳ Upload vers Cloudinary (folder: trash_reports/abc123)...
   ✅ Upload réussi! URL: https://res.cloudinary.com/...
   ```

7. **Si l'upload réussit** :
   - Vous verrez une snackbar verte "X photo(s) ajoutée(s) ✓"
   - L'image apparaîtra dans la liste des photos

8. **Vérifier sur Cloudinary** :
   - Allez dans [Media Library](https://console.cloudinary.com/console/media_library)
   - Vous verrez vos images dans le dossier `trash_reports/`

---

## 🔧 Dépannage

### ❌ Erreur : "Configuration Cloudinary manquante"

**Symptôme** : Snackbar rouge avec le message de configuration manquante

**Solution** :
1. Vérifiez que vous avez bien remplacé :
   - `YOUR_CLOUD_NAME_HERE` → votre cloud name
   - `YOUR_UPLOAD_PRESET_HERE` → votre preset name
2. Relancez l'application après modification

### ❌ Erreur : "Upload failed" ou "401 Unauthorized"

**Symptôme** : L'upload échoue avec une erreur 401

**Causes possibles** :
1. ❌ **Signing Mode incorrect**
   - Solution : Vérifiez que votre preset est en mode **"Unsigned"**
   - Allez dans Settings > Upload > Votre preset > Edit
   - Changez "Signing Mode" en "Unsigned"

2. ❌ **Nom du preset incorrect**
   - Solution : Vérifiez que le nom dans `cloudinary_config.dart` correspond exactement au nom dans Cloudinary

3. ❌ **Cloud name incorrect**
   - Solution : Vérifiez votre cloud name dans le Dashboard Cloudinary

### ❌ Erreur : "Invalid image file"

**Symptôme** : L'upload échoue avec une erreur de fichier invalide

**Solution** :
1. Vérifiez les formats autorisés dans votre Upload Preset
2. Ajoutez les formats manquants : jpg, png, webp, heic

### ⚠️ L'image s'upload mais n'apparaît pas

**Symptôme** : Upload réussi dans la console, mais pas d'image visible

**Vérifications** :
1. Allez dans [Media Library](https://console.cloudinary.com/console/media_library)
2. Vérifiez si l'image existe
3. Vérifiez l'URL retournée dans la console
4. Testez l'URL dans le navigateur

---

## 📊 Vérifier votre usage

Pour suivre votre consommation :

1. Allez sur [Dashboard](https://console.cloudinary.com)
2. Section **"Usage"** en haut
3. Vous verrez :
   - Storage utilisé / 25 GB
   - Bandwidth utilisé / 25 GB
   - Transformations / mois

---

## 🎯 Résumé - Liste de contrôle

Avant de tester, vérifiez que vous avez :

- [ ] Créé un compte Cloudinary
- [ ] Copié votre **Cloud Name** du Dashboard
- [ ] Créé un **Upload Preset** en mode **Unsigned**
- [ ] Mis à jour `lib/config/cloudinary_config.dart` avec vos valeurs
- [ ] Lancé `flutter pub get` pour installer les dépendances
- [ ] Relancé l'application

---

## 📚 Ressources supplémentaires

- [Documentation Cloudinary Upload](https://cloudinary.com/documentation/upload_images)
- [Upload Presets Guide](https://cloudinary.com/documentation/upload_presets)
- [Cloudinary Flutter SDK](https://pub.dev/packages/cloudinary_public)

---

## 🆘 Besoin d'aide ?

Si vous rencontrez des problèmes :

1. Vérifiez les logs dans la console DevTools (F12)
2. Consultez la section Dépannage ci-dessus
3. Vérifiez votre configuration dans `lib/config/cloudinary_config.dart`

---

**Date** : 2025-12-29
**Version** : 1.0
**Status** : ✅ Ready to use
