//
// FSBockInfo.h
//

#define kFSBlockMagicNumber1 159
#define kFSBlockMagicNumber2 225

typedef struct _FSBlockInfo {
	unsigned char magicNumber1;
	unsigned char magicNumber2;
	short imagewidth;
	short imageheight;
	short blockleft;
	short blocktop;
	short blockwidth;
	short blockheight;
} FSBlockInfo;
