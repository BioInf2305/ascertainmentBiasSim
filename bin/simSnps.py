import sys
from pysam import VariantFile
import random



def generateSimNumList(nSim, maxRow):##generate list with length "nSim" within the range(1, maxRow)
    nSimList = []
    while len(nSimList)<nSim:
        n = random.randint(1, maxRow)
        if n not in [nSimList]:
            nSimList.append(n)
    return nSimList


def writeSimVcf(vcfIn, snpDensity, initRow, countSim):
    vcfInF = VariantFile(vcfIn)
    vcfOut = "Sim_"+str(countSim)+"_"+vcfIn
    vcfOutF = VariantFile(vcfOut,'w',header=vcfInF.header)
    rowCount = 0
    startPos = 0
    writeVcf = 0
    for rec in vcfInF.fetch():
        rowCount += 1
        if rowCount == initRow:
            vcfOutF.write(rec)
            startPos = rec.pos
            writeVcf = 1
        if (rec.pos >= (startPos + snpDensity) and writeVcf == 1):
            vcfOutF.write(rec)
            startPos = rec.pos
    vcfOutF.close()

def main(vcfIn, snpDensity, nSim, maxRow):
    nSimList = generateSimNumList(int(nSim), int(maxRow))
    countSim = 0
    for initRow in nSimList:###initRow indicates the position of first SNP to be selected
        countSim += 1
        writeSimVcf(vcfIn, int(snpDensity), int(initRow), countSim)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
