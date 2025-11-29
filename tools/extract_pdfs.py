from pathlib import Path
try:
    from pypdf import PdfReader
except Exception as e:
    print('pypdf not installed')
    raise

pdfs = [
    Path(r"d:\Kuliah\Prak Mobile\wida-collection\Pemrograman Mobile - Modul 5 - P1 - Location-Aware.pdf"),
    Path(r"d:\Kuliah\Prak Mobile\wida-collection\Pemrograman Mobile - Modul 5 - P2 - Location-Aware.pdf"),
]

for p in pdfs:
    print('\n' + '='*80)
    print('FILE:', p.name)
    print('='*80)
    if not p.exists():
        print('File not found:', p)
        continue
    try:
        reader = PdfReader(str(p))
        for i, page in enumerate(reader.pages):
            text = page.extract_text() or ''
            print(f'-- Page {i+1} --')
            print(text.strip())
    except Exception as ex:
        print('Error reading', p, ex)
