--!strict

export type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

export type Rarity = "Comum" | "Incomum" | "Raro" | "Épico"

export type FishDef = {
	id: string,
	name: string,
	island: number,
	lureTier: number, -- tier da isca que atrai esta espécie (LureDef.tier)
	rarity: Rarity,
	baseValue: number, -- $ antes dos multiplicadores de peso/raridade
	weightRange: { min: number, max: number }, -- kg
	aggressive: boolean,
	health: number?, -- só peixes agressivos
	pullStrength: number, -- 1..10, força dos puxões no minijogo
}

export type LureDef = {
	id: string,
	name: string,
	tier: number,
	island: number, -- ilha onde é liberada
	price: number,
}

export type RodDef = {
	id: string,
	name: string,
	price: number,
	strength: number, -- 1..10, reduz o ganho de tensão
	resistance: number, -- 1..10, tensão máxima
}

export type WeaponDef = {
	id: string,
	name: string,
	price: number,
	damage: number,
}

return {}
