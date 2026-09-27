--!strict

export type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

return {}
