#include <dae.h>
#include <dae/daeDom.h>
#include <dom/domGlsl_newparam.h>
#include <dae/daeMetaCMPolicy.h>
#include <dae/daeMetaSequence.h>
#include <dae/daeMetaChoice.h>
#include <dae/daeMetaGroup.h>
#include <dae/daeMetaAny.h>
#include <dae/daeMetaElementAttribute.h>

daeElementRef
domGlsl_newparam::create(DAE& dae)
{
	domGlsl_newparamRef ref = new domGlsl_newparam(dae);
	return ref;
}


daeMetaElement *
domGlsl_newparam::registerElement(DAE& dae)
{
	daeMetaElement* meta = dae.getMeta(ID());
	if ( meta != NULL ) return meta;

	meta = new daeMetaElement(dae);
	dae.setMeta(ID(), *meta);
	meta->setName( "glsl_newparam" );
	meta->registerClass(domGlsl_newparam::create);

	daeMetaCMPolicy *cm = NULL;
	daeMetaElementAttribute *mea = NULL;
	cm = new daeMetaSequence( meta, cm, 0, 1, 1 );

	mea = new daeMetaElementArrayAttribute( meta, cm, 0, 0, -1 );
	mea->setName( "annotate" );
	mea->setOffset( daeOffsetOf(domGlsl_newparam,elemAnnotate_array) );
	mea->setElementType( domFx_annotate::registerElement(dae) );
	cm->appendChild( mea );

	mea = new daeMetaElementAttribute( meta, cm, 1, 0, 1 );
	mea->setName( "semantic" );
	mea->setOffset( daeOffsetOf(domGlsl_newparam,elemSemantic) );
	mea->setElementType( domGlsl_newparam::domSemantic::registerElement(dae) );
	cm->appendChild( mea );

	mea = new daeMetaElementAttribute( meta, cm, 2, 0, 1 );
	mea->setName( "modifier" );
	mea->setOffset( daeOffsetOf(domGlsl_newparam,elemModifier) );
	mea->setElementType( domGlsl_newparam::domModifier::registerElement(dae) );
	cm->appendChild( mea );

	mea = new daeMetaElementAttribute( meta, cm, 3, 1, 1 );
	mea->setName( "glsl_value" );
	mea->setOffset( daeOffsetOf(domGlsl_newparam,elemGlsl_value) );
	mea->setElementType( domGlsl_value::registerElement(dae) );
	cm->appendChild( new daeMetaGroup( mea, meta, cm, 3, 1, 1 ) );

	cm->setMaxOrdinal( 3 );
	meta->setCMRoot( cm );	

	//	Add attribute: sid
	{
		daeMetaAttribute *ma = new daeMetaAttribute;
		ma->setName( "sid" );
		ma->setType( dae.getAtomicTypes().get("Sid"));
		ma->setOffset( daeOffsetOf( domGlsl_newparam , attrSid ));
		ma->setContainer( meta );
		ma->setIsRequired( true );
	
		meta->appendAttribute(ma);
	}

	meta->setElementSize(sizeof(domGlsl_newparam));
	meta->validate();

	return meta;
}

daeElementRef
domGlsl_newparam::domSemantic::create(DAE& dae)
{
	domGlsl_newparam::domSemanticRef ref = new domGlsl_newparam::domSemantic(dae);
	return ref;
}


daeMetaElement *
domGlsl_newparam::domSemantic::registerElement(DAE& dae)
{
	daeMetaElement* meta = dae.getMeta(ID());
	if ( meta != NULL ) return meta;

	meta = new daeMetaElement(dae);
	dae.setMeta(ID(), *meta);
	meta->setName( "semantic" );
	meta->registerClass(domGlsl_newparam::domSemantic::create);

	meta->setIsInnerClass( true );
	//	Add attribute: _value
	{
		daeMetaAttribute *ma = new daeMetaAttribute;
		ma->setName( "_value" );
		ma->setType( dae.getAtomicTypes().get("xsNCName"));
		ma->setOffset( daeOffsetOf( domGlsl_newparam::domSemantic , _value ));
		ma->setContainer( meta );
		meta->appendAttribute(ma);
	}

	meta->setElementSize(sizeof(domGlsl_newparam::domSemantic));
	meta->validate();

	return meta;
}

daeElementRef
domGlsl_newparam::domModifier::create(DAE& dae)
{
	domGlsl_newparam::domModifierRef ref = new domGlsl_newparam::domModifier(dae);
	return ref;
}


daeMetaElement *
domGlsl_newparam::domModifier::registerElement(DAE& dae)
{
	daeMetaElement* meta = dae.getMeta(ID());
	if ( meta != NULL ) return meta;

	meta = new daeMetaElement(dae);
	dae.setMeta(ID(), *meta);
	meta->setName( "modifier" );
	meta->registerClass(domGlsl_newparam::domModifier::create);

	meta->setIsInnerClass( true );
	//	Add attribute: _value
	{
		daeMetaAttribute *ma = new daeMetaAttribute;
		ma->setName( "_value" );
		ma->setType( dae.getAtomicTypes().get("Fx_modifier"));
		ma->setOffset( daeOffsetOf( domGlsl_newparam::domModifier , _value ));
		ma->setContainer( meta );
		meta->appendAttribute(ma);
	}

	meta->setElementSize(sizeof(domGlsl_newparam::domModifier));
	meta->validate();

	return meta;
}

