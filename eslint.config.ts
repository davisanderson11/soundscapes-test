// @ts-ignore (TODO: DType this)
import react from "eslint-plugin-react"
import eslint from "@eslint/js"
import tseslint from "typescript-eslint"
import prettier from "eslint-config-prettier"

export default tseslint.config(
    { files: ["packages/app/**/*"], ...react.configs.flat["jsx-runtime"] },
    prettier,
    eslint.configs.recommended,
    ...tseslint.configs.strictTypeChecked,
    ...tseslint.configs.stylisticTypeChecked,
    { languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: __dirname } } },
    { ignores: ["packages/app/android/", "packages/app/babel.config.js", "eslint.config.ts"] },
    {
        rules: {
            "@typescript-eslint/no-confusing-void-expression": "off",
            "@typescript-eslint/no-non-null-assertion": "off",
            "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
            "@typescript-eslint/no-misused-promises": [
                "error",
                { checksVoidReturn: { attributes: false } }
            ],
            "@typescript-eslint/no-unused-vars": [
                "warn",
                { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }
            ]
        }
    }
)
