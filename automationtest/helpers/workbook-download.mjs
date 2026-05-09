import xlsx from 'xlsx'

export async function readWorkbookFromDownload(download) {
  const filePath = await download.path()
  const workbook = xlsx.readFile(filePath)

  return {
    getCell(sheetName, ref) {
      const sheet = workbook.Sheets[sheetName]
      return sheet?.[ref]?.v ?? ''
    },
  }
}
