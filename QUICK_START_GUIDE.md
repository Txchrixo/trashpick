# Guide de Démarrage Rapide - TrashPicker Auth Refactored

## 🚀 Lancer l'Application

```bash
# Nettoyer et récupérer les dépendances
flutter clean
flutter pub get

# Lancer l'app
flutter run
```

## 📱 Test du Flow Complet

### 1. Premier Lancement
✅ L'app devrait afficher l'**écran Welcome** avec:
- Logo/icône recycling
- Titre "TrashPicker"
- Description
- Bouton "Commencer"

### 2. Créer un Compte (Signup)

**Étapes**:
1. Cliquer sur "Commencer"
2. Choisir "Créer un compte"
3. **Écran Phone**:
   - Voir le drapeau 🇨🇲 et +237
   - Entrer un numéro à 9 chiffres (ex: 612345678)
   - Cliquer "Continuer"
4. **Écran OTP**:
   - Entrer le code reçu par SMS (ou code de test Firebase)
   - Cliquer "Vérifier"
5. **Écran Complete Profile**:
   - Remplir TOUS les champs:
     - Nom complet: Jean Dupont
     - Nom du foyer: Maison Dupont
     - Quartier: Bonamoussadi
     - Adresse: Rue de la Paix, après la pharmacie
     - Téléphone: (pré-rempli)
     - Mot de passe: minimum 6 caractères
     - Confirmer le mot de passe
   - Cliquer "Créer mon compte"
6. ✅ **Redirection vers Client Home Dashboard**

### 3. Se Déconnecter

**Depuis le Dashboard Client**:
1. Cliquer sur l'icône profil (en haut à droite)
2. Choisir "Se déconnecter"
3. ✅ Retour à l'écran "Auth Choice"

### 4. Se Reconnecter (Login)

**Étapes**:
1. Sur l'écran Auth Choice, choisir "Se connecter"
2. **Écran Login**:
   - Entrer le numéro (ex: 612345678)
   - Entrer le mot de passe
   - Cliquer "Se connecter"
3. ✅ **Redirection vers Client Home Dashboard**

### 5. Modifier le Profil

**Depuis le Dashboard Client**:
1. Cliquer sur l'icône profil
2. Choisir "Mon compte"
3. **Écran Account**:
   - Modifier n'importe quel champ (sauf téléphone)
   - Cliquer "Enregistrer"
   - ✅ Message de succès

### 6. Changer le Mot de Passe

**Depuis l'écran Account**:
1. Cliquer sur "Changer le mot de passe"
2. **Dialog**:
   - Mot de passe actuel
   - Nouveau mot de passe (min 6 caractères)
   - Confirmer le nouveau mot de passe
   - Cliquer "Changer"
3. ✅ Message de succès
4. Se déconnecter et se reconnecter avec le nouveau mot de passe

## 🧪 Testing avec Firebase

### Configuration des Numéros de Test

**Firebase Console** → Authentication → Sign-in method → Phone:

1. Ajouter un numéro de test:
   ```
   Numéro: +237600000000
   Code: 123456
   ```

2. Dans l'app, utiliser:
   - Téléphone: `600000000` (sans +237)
   - Code OTP: `123456`

### Avantages des Numéros de Test
- ✅ Pas de SMS réel envoyé
- ✅ Pas de coût
- ✅ Vérification instantanée
- ✅ Idéal pour développement

## 🔍 Vérification dans Firebase

### Authentication
**Firebase Console** → Authentication → Users

Vérifier qu'un user a été créé avec:
- **Provider**: Phone
- **Provider**: Password (fake email `237XXXXXXXXX@trashpicker.app`)
- UID unique

### Firestore
**Firebase Console** → Firestore Database → users collection

Vérifier le document user:
```json
{
  "id": "...",
  "phone": "+237612345678",
  "name": "Jean Dupont",
  "role": "client",
  "address": "Rue de la Paix...",
  "quartier": "Bonamoussadi",
  "foyer": "Maison Dupont",
  "createdAt": "...",
  "updatedAt": "...",
  "status": "active"
}
```

## ⚠️ Troubleshooting

### Erreur: "Invalid phone number"
**Solution**: Vérifier que le numéro a bien 9 chiffres (sans +237)

### Erreur: "Invalid verification code"
**Solutions**:
- Vérifier le code SMS reçu
- Ou utiliser un numéro de test Firebase avec le code configuré

### Erreur: "User not found" au login
**Cause**: Le user n'a pas de mot de passe lié
**Solution**: Recréer le compte via le flow signup complet

### Erreur: "Session expired"
**Solution**: Recommencer le flow signup depuis le début

### L'app affiche toujours le Welcome Screen alors que je suis connecté
**Solution**: Redémarrer l'app (hot reload ne suffit pas pour `initialRoute`)

## 📋 Checklist Avant Production

### Firebase Configuration
- [ ] Phone Authentication activé
- [ ] Email/Password Authentication activé
- [ ] Numéros de test configurés (développement)
- [ ] Firestore rules configurées
- [ ] Google Maps API configurée

### Testing
- [ ] Flow signup complet testé
- [ ] Flow login testé
- [ ] Logout testé
- [ ] Modification profil testée
- [ ] Changement mot de passe testé
- [ ] Navigation entre écrans testée

### Sécurité
- [ ] Firestore rules empêchent l'accès non autorisé
- [ ] Validation côté serveur (Cloud Functions si nécessaire)
- [ ] Pas de clés API hardcodées dans le code

## 🎯 Flux Techniques Importants

### Conversion Téléphone → Fake Email
```
+237612345678 → 237612345678@trashpicker.app
```

### Stratégie d'Authentification
1. **Signup**:
   - Firebase Phone Auth (OTP)
   - `linkWithCredential()` Email/Password
   - Création user Firestore avec role = CLIENT

2. **Login**:
   - `signInWithEmailAndPassword()` avec fake email
   - Chargement user Firestore
   - Redirection selon le rôle

### Gestion des Rôles
- **CLIENT**: Créé via l'app mobile (signup)
- **PICKER**: Créé manuellement en base (backoffice admin)
- Redirection automatique selon le rôle au login

## 📞 Support

En cas de problème:
1. Vérifier les logs Firebase Console
2. Vérifier les logs Flutter (`flutter run -v`)
3. Vérifier que tous les packages sont installés (`flutter pub get`)
4. Nettoyer et rebuild (`flutter clean && flutter pub get && flutter run`)

---

**Bon développement ! 🚀**
