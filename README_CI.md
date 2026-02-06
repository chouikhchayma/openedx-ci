# 🔧 CI Documentation - Basic CI Checks

## Qu'est-ce que le CI (Continuous Integration) ?

Le CI est un système qui **teste automatiquement** ton code à chaque modification pour détecter les erreurs **avant** qu'elles n'arrivent en production.

---

## 🚀 Comment fonctionne notre CI ?

### Quand le CI se déclenche :
- ✅ À chaque **push** sur n'importe quelle branch
- ✅ À chaque **pull request** vers `main`

### Ce que le CI vérifie :

1. **YAML Lint** : Vérifie que les fichiers `.yml` et `.yaml` sont valides
2. **ShellCheck** : Vérifie que les scripts shell (`.sh`) n'ont pas d'erreurs

---

## ✅ Comment savoir si le CI passe ?

### Sur GitHub :
1. Va dans l'onglet **Actions**
2. Regarde le statut :
   - ✅ **Vert** = Tout est OK, tu peux merger
   - ❌ **Rouge** = Il y a des erreurs, il faut corriger

### Sur une Pull Request :
- En bas de la PR, tu verras : **"All checks have passed"** ✅
- Ou : **"Some checks were not successful"** ❌

---

## 🛠️ Comment corriger les erreurs courantes ?

### Erreur 1 : YAML invalide

**Message d'erreur :**
```
syntax error: mapping values are not allowed here
```

**Solution :**
- Vérifie l'indentation (utilise des **espaces**, pas des tabulations)
- Vérifie qu'il n'y a pas de `:` en trop
- Utilise un validateur YAML en ligne : https://www.yamllint.com/

---

### Erreur 2 : ShellCheck trouve des problèmes

**Message d'erreur :**
```
SC2086: Double quote to prevent globbing and word splitting
```

**Solution :**
- Mets les variables entre guillemets : `"$variable"` au lieu de `$variable`
- Exécute `shellcheck ton_script.sh` en local avant de push

---

### Erreur 3 : Le CI ne se lance pas

**Solutions :**
1. Vérifie que ton fichier est bien dans `.github/workflows/ci.yml`
2. Va dans **Actions** et active les workflows si nécessaire
3. Vérifie qu'il n'y a pas d'erreur de syntaxe dans `ci.yml`

---

## 🚫 Branch Protection

La branch `main` est **protégée** :
- ❌ Impossible de push directement sur `main`
- ✅ Tu dois créer une **Pull Request**
- ✅ Le CI **doit passer** avant de pouvoir merger

---

## 📚 Commandes utiles

### Tester YAML en local :
```bash
yamllint fichier.yml
```

### Tester un script shell en local :
```bash
shellcheck script.sh
```

---

## 🆘 Besoin d'aide ?

- Regarde les logs détaillés dans **Actions** → clique sur le workflow raté
- Lis le message d'erreur (souvent très explicite)
- Cherche l'erreur sur Google ou ChatGPT

---

✅ **CI = Code de qualité = Déploiements sûrs !**
