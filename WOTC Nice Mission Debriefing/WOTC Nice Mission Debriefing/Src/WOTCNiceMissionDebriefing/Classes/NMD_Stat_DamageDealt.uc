class NMD_Stat_DamageDealt extends NMD_BaseStat;

const ID = 'DamageDealt';

var localized string m_strDamageDealt;

var int DamageDealt;

function InitComponent()
{
	DamageDealt = 0;
}

function AddValue(int Amount)
{
	DamageDealt += Amount;
}

function int GetValue()
{
	return DamageDealt;
}

function string GetName()
{
	return m_strDamageDealt;
}

function string GetDisplayValue()
{
	return string(DamageDealt);
}

function name GetType()
{
	return ID;
}
